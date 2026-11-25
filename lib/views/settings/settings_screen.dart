import 'package:aethercast/core/theme/app_theme.dart';
import 'package:aethercast/core/utils/weather_formatter.dart';
import 'package:aethercast/viewmodels/location_viewmodel.dart';
import 'package:aethercast/viewmodels/weather_viewmodel.dart';
import 'package:aethercast/views/widgets/glass_card.dart';
import 'package:aethercast/views/widgets/smooth_tap.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Screen 4 (Tambahan): Info stasiun cuaca aktif, preferensi satuan (°C/°F,
/// km/j/mph) tersimpan di SharedPreferences, hapus riwayat, dan info Open-Meteo.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.onEditLocation,
  });

  final VoidCallback onEditLocation;

  @override
  Widget build(BuildContext context) {
    return Consumer2<WeatherViewModel, LocationViewModel>(
      builder: (context, weatherVm, locationVm, _) {
        final location = weatherVm.selectedLocation;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 114),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Pengaturan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  GlassIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: 'Ubah kota aktif',
                    onTap: onEditLocation,
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Kartu Stasiun Cuaca Aktif
              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.deepForestTeal,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                location.fullTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Stasiun Cuaca Aktif',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StationStatBox(
                            label: 'Garis Lintang',
                            value: '${location.latitude.toStringAsFixed(2)}°',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StationStatBox(
                            label: 'Garis Bujur',
                            value: '${location.longitude.toStringAsFixed(2)}°',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StationStatBox(
                            label: 'Zona Waktu',
                            value: weatherVm.timezoneShortLabel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bagian Preferensi
              Text(
                'Preferensi',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textOnDark,
                    ),
              ),
              const SizedBox(height: 10),

              // Toggle Satuan Suhu
              GlassCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                onTap: () =>
                    weatherVm.toggleTemperatureUnit(!weatherVm.useFahrenheit),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.circle,
                        size: 15,
                        color: AppTheme.warmAmber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Satuan Suhu (°C / °F)',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Switch(
                      value: weatherVm.useFahrenheit,
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF156165),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: AppTheme.deepForestTeal,
                      trackOutlineColor:
                          WidgetStateProperty.all(Colors.transparent),
                      onChanged: (val) => weatherVm.toggleTemperatureUnit(val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Pemilih Satuan Angin
              GlassCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                onTap: () => _showWindUnitDialog(context, weatherVm),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.air_rounded,
                        size: 18,
                        color: AppTheme.deepForestTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Satuan Angin (${weatherVm.windUnit.label})',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Hapus Riwayat Pencarian
              GlassCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                onTap: () => _confirmClearHistory(context, locationVm),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppTheme.deepForestTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hapus Riwayat Pencarian',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bagian Tentang
              Text(
                'Tentang',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textOnDark,
                    ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                radius: 22,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                onTap: () => _showAboutDialog(context),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppTheme.deepForestTeal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Data oleh Open-Meteo API',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          Text(
                            'Cuaca real-time & prakiraan per jam',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showWindUnitDialog(
    BuildContext context,
    WeatherViewModel weatherVm,
  ) async {
    final chosen = await showModalBottomSheet<WindSpeedUnit>(
      context: context,
      backgroundColor: const Color(0xFFE7EFEC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Satuan Kecepatan Angin',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final unit in WindSpeedUnit.values)
                  SmoothTap(
                    pressedScale: 0.97,
                    onTap: () => Navigator.of(ctx).pop(unit),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: Icon(
                        weatherVm.windUnit == unit
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: AppTheme.deepForestTeal,
                      ),
                      title: Text(
                        unit == WindSpeedUnit.kmh
                            ? 'Kilometer per jam (km/j)'
                            : 'Mil per jam (mph)',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (chosen != null) {
      await weatherVm.setWindUnit(chosen);
    }
  }

  Future<void> _confirmClearHistory(
    BuildContext context,
    LocationViewModel locationVm,
  ) async {
    if (locationVm.recentSearches.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Riwayat pencarian sudah kosong')),
        );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat Pencarian?'),
        content: const Text(
          'Riwayat pencarian kota yang tersimpan di penyimpanan lokal akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.deepForestTeal,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await locationVm.clearRecentSearches();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Riwayat pencarian berhasil dihapus')),
        );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tentang AetherCast'),
        content: const Text(
          'AetherCast mengambil data cuaca langsung dari Open-Meteo Weather Forecast API dan Geocoding API melalui HTTP GET.\n\n'
          'Arsitektur: Model-View-ViewModel (MVVM) dengan state management Provider dan penyimpanan lokal SharedPreferences.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.deepForestTeal,
            ),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

class _StationStatBox extends StatelessWidget {
  const _StationStatBox({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.34),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.42),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
