import 'package:aethercast/core/theme/app_theme.dart';
import 'package:aethercast/core/utils/weather_code_mapper.dart';
import 'package:aethercast/core/utils/weather_formatter.dart';
import 'package:aethercast/models/weather_model.dart';
import 'package:aethercast/viewmodels/weather_viewmodel.dart';
import 'package:aethercast/views/widgets/analytics_charts.dart';
import 'package:aethercast/views/widgets/glass_card.dart';
import 'package:aethercast/views/widgets/smooth_tap.dart';
import 'package:aethercast/views/widgets/state_feedback_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _AnalyticsMode { temperature, rainChance }

/// Screen 3 (Tambahan): Analitik prakiraan 7 hari dengan grafik batang interaktif,
/// kurva peluang hujan per jam, angin maksimum, dan kelembapan rata-rata.
class ForecastAnalyticsScreen extends StatefulWidget {
  const ForecastAnalyticsScreen({
    super.key,
    required this.onBackToHome,
  });

  final VoidCallback onBackToHome;

  @override
  State<ForecastAnalyticsScreen> createState() =>
      _ForecastAnalyticsScreenState();
}

class _ForecastAnalyticsScreenState extends State<ForecastAnalyticsScreen> {
  _AnalyticsMode _mode = _AnalyticsMode.temperature;
  int _selectedDays = 7;
  int? _manualBarIndex;

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherViewModel>(
      builder: (context, weatherVm, _) {
        final weather = weatherVm.weather;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 114),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GlassIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Kembali ke Beranda',
                    onTap: widget.onBackToHome,
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Analitik Prakiraan',
                            maxLines: 1,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<int>(
                    onSelected: (days) {
                      if (days == -1) {
                        weatherVm.fetchWeatherForSelectedLocation(
                          pullRefresh: true,
                        );
                      } else {
                        setState(() {
                          _selectedDays = days;
                          _manualBarIndex = null;
                        });
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 7, child: Text('Tampilkan 7 Hari')),
                      PopupMenuItem(value: 5, child: Text('Tampilkan 5 Hari')),
                      PopupMenuItem(value: 3, child: Text('Tampilkan 3 Hari')),
                      PopupMenuDivider(),
                      PopupMenuItem(value: -1, child: Text('Muat Ulang Data')),
                    ],
                    child: IgnorePointer(
                      child: GlassIconButton(
                        icon: Icons.more_horiz_rounded,
                        onTap: () {},
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter Pill Chips (Suhu / Peluang Hujan)
              Row(
                children: [
                  Expanded(
                    child: _FilterChipButton(
                      label: 'Suhu',
                      icon: Icons.circle,
                      iconColor: AppTheme.warmAmber,
                      iconSize: 12,
                      selected: _mode == _AnalyticsMode.temperature,
                      onTap: () => setState(() {
                        _mode = _AnalyticsMode.temperature;
                        _manualBarIndex = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FilterChipButton(
                      label: 'Peluang Hujan',
                      icon: Icons.cloud_queue_rounded,
                      iconColor: _mode == _AnalyticsMode.rainChance
                          ? AppTheme.rainBlue
                          : AppTheme.textOnDark,
                      iconSize: 16,
                      selected: _mode == _AnalyticsMode.rainChance,
                      onTap: () => setState(() {
                        _mode = _AnalyticsMode.rainChance;
                        _manualBarIndex = null;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (weatherVm.state == WeatherLoadState.loading ||
                  weatherVm.state == WeatherLoadState.initial)
                const LoadingWeatherView(
                  message: 'Memuat analitik prakiraan...',
                )
              else if (weatherVm.state == WeatherLoadState.error)
                ErrorStateCard(
                  message: weatherVm.errorMessage ??
                      'Tidak dapat memuat analitik prakiraan.',
                  onRetry: () => weatherVm.fetchWeatherForSelectedLocation(),
                )
              else if (weather == null || weather.daily.isEmpty)
                const EmptyStateCard(
                  icon: Icons.bar_chart_rounded,
                  title: 'Belum ada data analitik',
                  subtitle: 'Pilih kota untuk melihat analitik cuaca 7 hari.',
                )
              else
                _buildAnalyticsContent(context, weatherVm, weather),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsContent(
    BuildContext context,
    WeatherViewModel weatherVm,
    WeatherModel weather,
  ) {
    final daysSlice = weather.daily.take(_selectedDays).toList();

    final entries = daysSlice.map((day) {
      final label = WeatherFormatter.formatShortWeekday(day.date);
      if (_mode == _AnalyticsMode.temperature) {
        final converted = weatherVm.convertTemperature(day.temperature2mMax);
        return BarChartEntry(
          label: label,
          value: converted,
          formattedValue: '${converted.round()}°',
        );
      }
      return BarChartEntry(
        label: label,
        value: day.precipitationProbabilityMax.toDouble(),
        formattedValue: '${day.precipitationProbabilityMax}%',
      );
    }).toList();

    var defaultPeakIndex = 0;
    for (var i = 1; i < entries.length; i++) {
      if (entries[i].value > entries[defaultPeakIndex].value) {
        defaultPeakIndex = i;
      }
    }
    final activeIndex =
        (_manualBarIndex != null && _manualBarIndex! < entries.length)
            ? _manualBarIndex!
            : defaultPeakIndex;

    final headerHeadline = _mode == _AnalyticsMode.temperature
        ? weatherVm.formatTemperature(weather.averageMaxTemp(daysSlice.length))
        : '${weather.averageRainChance(daysSlice.length)}%';
    final headerCaption =
        _mode == _AnalyticsMode.temperature ? 'rata maks' : 'rata hujan';

    final hourlyRain = weather.todayHourlyPoints
        .map((p) => p.precipitationProbability)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kartu Grafik Batang Utama
        GlassCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              headerHeadline,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontSize: 24),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              headerCaption,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<int>(
                    onSelected: (days) => setState(() {
                      _selectedDays = days;
                      _manualBarIndex = null;
                    }),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 7, child: Text('7 Hari')),
                      PopupMenuItem(value: 5, child: Text('5 Hari')),
                      PopupMenuItem(value: 3, child: Text('3 Hari')),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_selectedDays Hari',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppTheme.textPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              WeeklyBarChart(
                entries: entries,
                selectedIndex: activeIndex,
                onSelectBar: (i) => setState(() => _manualBarIndex = i),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Bento Grid Bawah: Kiri Peluang Hujan + Kanan Angin & Kelembapan
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu Peluang Hujan
              Expanded(
                flex: 11,
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.water_drop_rounded,
                          size: 18,
                          color: AppTheme.softSkyBlue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: RainProbabilityAreaChart(
                            values: hourlyRain.isNotEmpty
                                ? hourlyRain
                                : daysSlice
                                    .map((d) => d.precipitationProbabilityMax)
                                    .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Peluang Hujan',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${weather.todayPeakRainProbability}%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontSize: 24),
                      ),
                      Text(
                        weather.todayPeakRainTimeLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Kolom Kanan: Angin Maks + Kelembapan Rata-rata
              Expanded(
                flex: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GlassCard(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                              color: AppTheme.warmAmber,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Angin Maks',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              weatherVm.formatWind(weather.weeklyMaxWindKmh),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 20),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            weather.weeklyMaxWindSubtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.water_drop_rounded,
                              size: 18,
                              color: AppTheme.deepForestTeal,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Kelembapan Rata-rata',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${weather.averageHumidity}%',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            WeatherCodeMapper.humidityComfort(
                              weather.averageHumidity,
                            ),
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
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SmoothTap(
      pressedScale: 0.95,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: selected
              ? Colors.white.withValues(alpha: 0.94)
              : Colors.white.withValues(alpha: 0.22),
          border: Border.all(
            color: Colors.white.withValues(alpha: selected ? 0.95 : 0.35),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: iconColor),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppTheme.textPrimary : AppTheme.textOnDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
