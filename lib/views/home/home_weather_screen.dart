import 'package:aethercast/core/theme/app_theme.dart';
import 'package:aethercast/core/utils/weather_code_mapper.dart';
import 'package:aethercast/core/utils/weather_formatter.dart';
import 'package:aethercast/models/weather_model.dart';
import 'package:aethercast/viewmodels/location_viewmodel.dart';
import 'package:aethercast/viewmodels/weather_viewmodel.dart';
import 'package:aethercast/views/widgets/glass_card.dart';
import 'package:aethercast/views/widgets/smooth_tap.dart';
import 'package:aethercast/views/widgets/state_feedback_widgets.dart';
import 'package:aethercast/views/widgets/weather_illustration.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Screen 1 (Wajib): Dasbor cuaca kota aktif, metrik hari ini, dan prakiraan 7 hari.
class HomeWeatherScreen extends StatelessWidget {
  const HomeWeatherScreen({
    super.key,
    required this.onSeeAllForecast,
    required this.onOpenSearch,
  });

  final VoidCallback onSeeAllForecast;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    return Consumer2<WeatherViewModel, LocationViewModel>(
      builder: (context, weatherVm, locationVm, _) {
        final location = weatherVm.selectedLocation;
        final isFav = locationVm.isFavorite(location);
        final weather = weatherVm.weather;
        final displayDate = weather?.current.time ?? DateTime.now();

        return RefreshIndicator(
          color: AppTheme.deepForestTeal,
          onRefresh: () =>
              weatherVm.fetchWeatherForSelectedLocation(pullRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 114),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Bar Atas
                Row(
                  children: [
                    Expanded(
                      child: SmoothTap(
                        pressedScale: 0.98,
                        onTap: onOpenSearch,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 20,
                                  color: AppTheme.deepForestTeal,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    location.headerTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 25, top: 2),
                              child: Text(
                                WeatherFormatter.formatHeaderDate(displayDate),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GlassIconButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Muat ulang cuaca',
                      onTap: () => weatherVm.fetchWeatherForSelectedLocation(
                        pullRefresh: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GlassIconButton(
                      icon: isFav
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      iconColor: isFav
                          ? AppTheme.warmAmber
                          : AppTheme.deepForestTeal,
                      tooltip: isFav
                          ? 'Hapus dari favorit'
                          : 'Simpan ke favorit',
                      onTap: () async {
                        final added =
                            await locationVm.toggleFavorite(location);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                added
                                    ? '${location.name} disimpan ke favorit'
                                    : '${location.name} dihapus dari favorit',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Banner peringatan jika refresh gagal tetapi cache tersedia
                if (weatherVm.errorMessage != null && weather != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      radius: 16,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: AppTheme.deepForestTeal,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              weatherVm.errorMessage!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (weatherVm.isRefreshing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: AppTheme.deepForestTeal,
                      backgroundColor: Colors.white24,
                    ),
                  ),

                // Switcher State: Loading / Error / Empty / Loaded
                _buildBody(context, weatherVm, weather),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    WeatherViewModel weatherVm,
    WeatherModel? weather,
  ) {
    switch (weatherVm.state) {
      case WeatherLoadState.initial:
      case WeatherLoadState.loading:
        return const LoadingWeatherView();
      case WeatherLoadState.error:
        return ErrorStateCard(
          message: weatherVm.errorMessage ??
              'Tidak dapat memuat data cuaca dari Open-Meteo.',
          onRetry: () => weatherVm.fetchWeatherForSelectedLocation(),
        );
      case WeatherLoadState.empty:
        return EmptyStateCard(
          icon: Icons.cloud_off_rounded,
          title: 'Data prakiraan tidak tersedia',
          subtitle:
              'Open-Meteo tidak mengembalikan prakiraan harian untuk lokasi ini.',
          actionLabel: 'Cari kota lain',
          onAction: onOpenSearch,
        );
      case WeatherLoadState.loaded:
        if (weather == null) return const LoadingWeatherView();
        final current = weather.current;
        final condition = WeatherCodeMapper.fromCode(current.weatherCode);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Weather Glass Card
            GlassCard(
              padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            weatherVm.formatTemperature(current.temperature2m),
                            style: Theme.of(context).textTheme.displayLarge,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          condition.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.deepForestTeal,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Terasa seperti ${weatherVm.formatTemperature(current.apparentTemperature)}',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  WeatherIllustration(
                    kind: condition.kind,
                    isDay: current.isDay,
                    size: 98,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bagian Metrik Hari Ini
            Text(
              'Metrik Hari Ini',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textOnDark,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricBentoCard(
                    title: 'Kelembapan',
                    value: '${current.relativeHumidity2m}%',
                    status: WeatherCodeMapper.humidityStatus(
                      current.relativeHumidity2m,
                    ),
                    badgeColor: AppTheme.softSkyBlue,
                    badgeIcon: Icons.water_drop_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricBentoCard(
                    title: 'Angin',
                    value: weatherVm.formatWind(current.windSpeed10m),
                    status: WeatherCodeMapper.windStatus(current.windSpeed10m),
                    badgeColor: AppTheme.warmAmber,
                    badgeIcon: Icons.air_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricBentoCard(
                    title: 'Curah Hujan',
                    value: WeatherFormatter.formatPrecipitation(
                      current.precipitation,
                    ),
                    status: WeatherCodeMapper.precipitationStatus(
                      current.precipitation,
                    ),
                    badgeColor: AppTheme.rainBlue,
                    badgeIcon: Icons.grain_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Header Prakiraan 7 Hari
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Prakiraan 7 Hari',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textOnDark,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                SmoothTap(
                  pressedScale: 0.94,
                  onTap: onSeeAllForecast,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Lihat semua',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSubtleOnDark,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Kartu Daftar Prakiraan 7 Hari
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: List.generate(weather.daily.length, (index) {
                  final day = weather.daily[index];
                  final dayCondition =
                      WeatherCodeMapper.fromCode(day.weatherCode);
                  final rainChance = day.precipitationProbabilityMax;
                  final hasRain = rainChance >= 30;

                  return Column(
                    children: [
                      SmoothTap(
                        pressedScale: 0.98,
                        onTap: onSeeAllForecast,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 64,
                                child: Text(
                                  WeatherFormatter.formatForecastDay(
                                    day.date,
                                    index,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        fontWeight: index == 0
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: WeatherIllustration(
                                    kind: dayCondition.kind,
                                    size: 24,
                                  ),
                                ),
                              ),
                              Container(
                                width: 54,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: hasRain
                                      ? AppTheme.softSkyBlue
                                          .withValues(alpha: 0.34)
                                      : Colors.black.withValues(alpha: 0.14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$rainChance%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: hasRain
                                        ? const Color(0xFF0A3D58)
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 78,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${weatherVm.formatTemperature(day.temperature2mMin, showUnit: false)} / ${weatherVm.formatTemperature(day.temperature2mMax, showUnit: false)}',
                                    textAlign: TextAlign.right,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (index < weather.daily.length - 1)
                        Divider(
                          height: 1,
                          thickness: 0.7,
                          color: Colors.white.withValues(alpha: 0.20),
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

class _MetricBentoCard extends StatelessWidget {
  const _MetricBentoCard({
    required this.title,
    required this.value,
    required this.status,
    required this.badgeColor,
    required this.badgeIcon,
  });

  final String title;
  final String value;
  final String status;
  final Color badgeColor;
  final IconData badgeIcon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 13, 10, 11),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.deepForestTeal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: AppTheme.textOnDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor,
                ),
                child: Icon(badgeIcon, size: 15, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
