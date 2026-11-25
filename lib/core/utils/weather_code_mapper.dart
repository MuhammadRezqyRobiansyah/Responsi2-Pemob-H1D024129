import 'package:aethercast/core/theme/app_theme.dart';
import 'package:aethercast/core/utils/weather_formatter.dart';
import 'package:flutter/material.dart';

/// Kategori visual untuk merender ilustrasi cuaca custom.
enum WeatherKind {
  clear,
  partlyCloudy,
  cloudy,
  fog,
  drizzle,
  rain,
  thunderstorm,
  snow,
}

/// Metadata yang diturunkan dari kode cuaca WMO Open-Meteo.
class WeatherConditionInfo {
  const WeatherConditionInfo({
    required this.label,
    required this.shortLabel,
    required this.badgeColor,
    required this.icon,
    required this.kind,
  });

  final String label;
  final String shortLabel;
  final Color badgeColor;
  final IconData icon;
  final WeatherKind kind;
}

/// Memetakan kode cuaca WMO dan ambang batas meteorologi ke label
/// berbahasa Indonesia, ikon, serta warna badge status.
class WeatherCodeMapper {
  WeatherCodeMapper._();

  static WeatherConditionInfo fromCode(int code) {
    return switch (code) {
      0 => const WeatherConditionInfo(
          label: 'Cerah',
          shortLabel: 'Cerah',
          badgeColor: Color(0xFFB48C38),
          icon: Icons.wb_sunny_rounded,
          kind: WeatherKind.clear,
        ),
      1 || 2 => const WeatherConditionInfo(
          label: 'Cerah Berawan',
          shortLabel: 'Berawan',
          badgeColor: Color(0xFF5D7675),
          icon: Icons.wb_cloudy_rounded,
          kind: WeatherKind.partlyCloudy,
        ),
      3 => const WeatherConditionInfo(
          label: 'Mendung',
          shortLabel: 'Mendung',
          badgeColor: Color(0xFF4F696B),
          icon: Icons.cloud_rounded,
          kind: WeatherKind.cloudy,
        ),
      45 || 48 => const WeatherConditionInfo(
          label: 'Berkabut',
          shortLabel: 'Kabut',
          badgeColor: Color(0xFF607678),
          icon: Icons.foggy,
          kind: WeatherKind.fog,
        ),
      51 || 53 || 55 || 56 || 57 => const WeatherConditionInfo(
          label: 'Gerimis Ringan',
          shortLabel: 'Gerimis',
          badgeColor: Color(0xFF4B8CA8),
          icon: Icons.grain_rounded,
          kind: WeatherKind.drizzle,
        ),
      61 || 80 => const WeatherConditionInfo(
          label: 'Hujan Ringan',
          shortLabel: 'Hujan Ringan',
          badgeColor: Color(0xFF468EB3),
          icon: Icons.water_drop_rounded,
          kind: WeatherKind.rain,
        ),
      63 || 65 || 66 || 67 || 81 || 82 => const WeatherConditionInfo(
          label: 'Hujan Deras',
          shortLabel: 'Hujan',
          badgeColor: AppTheme.rainBlue,
          icon: Icons.water_drop_rounded,
          kind: WeatherKind.rain,
        ),
      71 || 73 || 75 || 77 || 85 || 86 => const WeatherConditionInfo(
          label: 'Hujan Salju',
          shortLabel: 'Salju',
          badgeColor: Color(0xFF5B87A6),
          icon: Icons.ac_unit_rounded,
          kind: WeatherKind.snow,
        ),
      95 || 96 || 99 => const WeatherConditionInfo(
          label: 'Badai Petir',
          shortLabel: 'Badai',
          badgeColor: Color(0xFF285568),
          icon: Icons.thunderstorm_rounded,
          kind: WeatherKind.thunderstorm,
        ),
      _ => const WeatherConditionInfo(
          label: 'Berawan',
          shortLabel: 'Berawan',
          badgeColor: Color(0xFF5D7675),
          icon: Icons.cloud_queue_rounded,
          kind: WeatherKind.partlyCloudy,
        ),
    };
  }

  static String humidityStatus(int humidity) {
    if (humidity < 40) return 'Kering';
    if (humidity <= 75) return 'Normal';
    return 'Lembap';
  }

  static String humidityComfort(int humidity) {
    if (humidity < 40) return 'Udara Kering';
    if (humidity <= 75) return 'Nyaman';
    return 'Udara Lembap';
  }

  static String windStatus(double speedKmh) =>
      WeatherFormatter.windStatus(speedKmh);

  static String precipitationStatus(double mm) {
    if (mm <= 0.05) return 'Kering';
    if (mm < 2.5) return 'Ringan';
    if (mm < 10.0) return 'Sedang';
    return 'Lebat';
  }

  static String compassDirection(int degrees) =>
      WeatherFormatter.compassDirection(degrees);
}
