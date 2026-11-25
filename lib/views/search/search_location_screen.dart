import 'dart:async';

import 'package:aethercast/core/theme/app_theme.dart';
import 'package:aethercast/core/utils/weather_code_mapper.dart';
import 'package:aethercast/models/location_model.dart';
import 'package:aethercast/viewmodels/location_viewmodel.dart';
import 'package:aethercast/viewmodels/weather_viewmodel.dart';
import 'package:aethercast/views/widgets/glass_card.dart';
import 'package:aethercast/views/widgets/smooth_tap.dart';
import 'package:aethercast/views/widgets/state_feedback_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Screen 2 (Wajib): Pencarian kota langsung ke Geocoding API,
/// daftar lokasi favorit permanen di SharedPreferences, dan riwayat pencarian.
class SearchLocationScreen extends StatefulWidget {
  const SearchLocationScreen({super.key, required this.onLocationSelected});

  final VoidCallback onLocationSelected;

  @override
  State<SearchLocationScreen> createState() => _SearchLocationScreenState();
}

class _SearchLocationScreenState extends State<SearchLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<LocationViewModel>().searchCities(value);
    });
  }

  void _onSearchSubmitted(String value) {
    _debounce?.cancel();
    context.read<LocationViewModel>().searchCities(value);
  }

  Future<void> _selectCity(LocationModel location) async {
    _searchFocusNode.unfocus();
    final weatherVm = context.read<WeatherViewModel>();
    final locationVm = context.read<LocationViewModel>();

    await locationVm.addRecentSearch(location);
    unawaited(weatherVm.selectLocation(location));
    _searchController.clear();
    locationVm.clearSearch();
    setState(() {});
    widget.onLocationSelected();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocationViewModel, WeatherViewModel>(
      builder: (context, locationVm, weatherVm, _) {
        final hasQuery = _searchController.text.trim().isNotEmpty;

        return RefreshIndicator(
          color: AppTheme.deepForestTeal,
          onRefresh: () => locationVm.refreshFavoriteWeathers(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 114),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lokasi',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    GlassIconButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Fokus ke pencarian kota',
                      onTap: () => _searchFocusNode.requestFocus(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Pill Pencarian Kaca
                GlassCard(
                  radius: 30,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppTheme.deepForestTeal,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          textInputAction: TextInputAction.search,
                          onChanged: _onSearchChanged,
                          onSubmitted: _onSearchSubmitted,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Cari nama kota...',
                            hintStyle: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textMuted),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      if (hasQuery)
                        SmoothTap(
                          pressedScale: 0.85,
                          onTap: () {
                            _debounce?.cancel();
                            _searchController.clear();
                            locationVm.clearSearch();
                            setState(() {});
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.close_rounded,
                              size: 19,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bagian Hasil Pencarian Live Geocoding
                if (hasQuery) ...[
                  _buildSearchResultsSection(context, locationVm),
                  const SizedBox(height: 22),
                ],

                // Bagian Lokasi Favorit
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Lokasi Favorit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.textOnDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${locationVm.favorites.length} kota',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textSubtleOnDark),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (locationVm.favorites.isEmpty)
                  EmptyStateCard(
                    icon: Icons.star_border_rounded,
                    title: 'Belum ada kota favorit',
                    subtitle:
                        'Cari kota di atas atau ketuk ikon bintang di Beranda untuk menyimpannya di sini.',
                    actionLabel: 'Cari Kota',
                    onAction: () => _searchFocusNode.requestFocus(),
                  )
                else
                  Column(
                    children: List.generate(locationVm.favorites.length, (i) {
                      final city = locationVm.favorites[i];
                      final liveWeather = locationVm.weatherForFavorite(city);
                      final isLoadingTemp =
                          locationVm.isLoadingFavoriteWeather(city);
                      final condition = liveWeather != null
                          ? WeatherCodeMapper.fromCode(liveWeather.weatherCode)
                          : null;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: i < locationVm.favorites.length - 1 ? 12 : 0,
                        ),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          onTap: () => _selectCity(city),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      city.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      city.subtitleWithCoords,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color:
                                            (condition?.badgeColor ??
                                                    AppTheme.textMuted)
                                                .withValues(alpha: 0.25),
                                      ),
                                      child: Text(
                                        condition?.shortLabel ??
                                            (isLoadingTemp
                                                ? 'Memuat...'
                                                : 'Tersimpan'),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (liveWeather != null)
                                Text(
                                  weatherVm.formatTemperature(
                                    liveWeather.temperature2m,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontSize: 23),
                                )
                              else if (isLoadingTemp)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.deepForestTeal,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              SmoothTap(
                                pressedScale: 0.84,
                                onTap: () => locationVm.toggleFavorite(city),
                                child: const Tooltip(
                                  message: 'Hapus favorit',
                                  child: Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.star_rounded,
                                      color: AppTheme.warmAmber,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),

                const SizedBox(height: 22),

                // Bagian Pencarian Terakhir
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Pencarian Terakhir',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.textOnDark),
                      ),
                    ),
                    if (locationVm.recentSearches.isNotEmpty)
                      SmoothTap(
                        pressedScale: 0.92,
                        onTap: () => locationVm.clearRecentSearches(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Text(
                            'Hapus semua',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSubtleOnDark,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (locationVm.recentSearches.isEmpty)
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    radius: 18,
                    topAlpha: 0.25,
                    bottomAlpha: 0.16,
                    child: Text(
                      'Kota yang Anda pilih dari pencarian akan muncul di sini untuk akses cepat.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textPrimary),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: locationVm.recentSearches.map((city) {
                      final isActive = city == weatherVm.selectedLocation;
                      return SmoothTap(
                        pressedScale: 0.93,
                        onTap: () => _selectCity(city),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: isActive
                                ? AppTheme.deepForestTeal
                                : Colors.white.withValues(alpha: 0.30),
                            border: Border.all(
                              color: isActive
                                  ? AppTheme.deepForestTeal
                                  : Colors.white.withValues(alpha: 0.42),
                            ),
                          ),
                          child: Text(
                            city.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppTheme.textOnDark
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResultsSection(
    BuildContext context,
    LocationViewModel locationVm,
  ) {
    switch (locationVm.searchState) {
      case SearchLoadState.idle:
      case SearchLoadState.loading:
        return GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppTheme.deepForestTeal,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Mencari "${_searchController.text.trim()}" di Open-Meteo...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      case SearchLoadState.error:
        return ErrorStateCard(
          title: 'Pencarian kota gagal',
          message:
              locationVm.searchErrorMessage ??
              'Tidak dapat menjangkau Open-Meteo Geocoding API.',
          onRetry: () => locationVm.searchCities(_searchController.text),
        );
      case SearchLoadState.empty:
        return EmptyStateCard(
          icon: Icons.location_off_rounded,
          title: 'Kota tidak ditemukan',
          subtitle:
              'Tidak ada hasil untuk "${locationVm.lastQuery}". Coba ejaan atau nama kota lain.',
        );
      case SearchLoadState.loaded:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Hasil Pencarian',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textOnDark,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${locationVm.searchResults.length} ditemukan',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppTheme.textSubtleOnDark),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                children: List.generate(locationVm.searchResults.length, (i) {
                  final loc = locationVm.searchResults[i];
                  final fav = locationVm.isFavorite(loc);
                  final coords =
                      '${loc.latitude.toStringAsFixed(2)}°, ${loc.longitude.toStringAsFixed(2)}°';

                  return Column(
                    children: [
                      SmoothTap(
                        pressedScale: 0.98,
                        onTap: () => _selectCity(loc),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.deepForestTeal
                                  .withValues(alpha: 0.14),
                            ),
                            child: const Icon(
                              Icons.place_rounded,
                              color: AppTheme.deepForestTeal,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            loc.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Text(
                            loc.searchSubtitle.isNotEmpty
                                ? '${loc.searchSubtitle} · $coords'
                                : coords,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: SmoothTap(
                            pressedScale: 0.84,
                            onTap: () => locationVm.toggleFavorite(loc),
                            child: Tooltip(
                              message: fav
                                  ? 'Hapus dari favorit'
                                  : 'Simpan ke favorit',
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Icon(
                                  fav
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: fav
                                      ? AppTheme.warmAmber
                                      : AppTheme.deepForestTeal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (i < locationVm.searchResults.length - 1)
                        Divider(
                          height: 1,
                          indent: 14,
                          endIndent: 14,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        );
    }
  }
}
