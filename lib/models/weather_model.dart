import 'package:aethercast/core/utils/weather_formatter.dart';

/// Current meteorological measurements from Open-Meteo `current` block.
class CurrentWeather {
  const CurrentWeather({
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.apparentTemperature,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed10m,
    required this.isDay,
    required this.time,
  });

  final double temperature2m;
  final int relativeHumidity2m;
  final double apparentTemperature;
  final double precipitation;
  final int weatherCode;
  final double windSpeed10m;
  final bool isDay;
  final DateTime time;

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature2m: (json['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      relativeHumidity2m:
          (json['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      apparentTemperature:
          (json['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      windSpeed10m: (json['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      isDay: ((json['is_day'] as num?)?.toInt() ?? 1) == 1,
      time: DateTime.tryParse((json['time'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}

/// Daily forecast metrics from Open-Meteo `daily` block.
class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.temperature2mMax,
    required this.temperature2mMin,
    required this.precipitationProbabilityMax,
    required this.windSpeed10mMax,
    required this.windDirection10mDominant,
  });

  final DateTime date;
  final int weatherCode;
  final double temperature2mMax;
  final double temperature2mMin;
  final int precipitationProbabilityMax;
  final double windSpeed10mMax;
  final int windDirection10mDominant;
}

/// Hourly forecast sample used for today's rain curve and average humidity.
class HourlyForecastPoint {
  const HourlyForecastPoint({
    required this.time,
    required this.relativeHumidity2m,
    required this.precipitationProbability,
  });

  final DateTime time;
  final int relativeHumidity2m;
  final int precipitationProbability;
}

/// Complete weather payload returned by Open-Meteo Forecast API.
class WeatherModel {
  const WeatherModel({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.timezoneAbbreviation,
    required this.current,
    required this.daily,
    required this.hourly,
  });

  final double latitude;
  final double longitude;
  final String timezone;
  final String timezoneAbbreviation;
  final CurrentWeather current;
  final List<DailyForecast> daily;
  final List<HourlyForecastPoint> hourly;

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final currentJson =
        (json['current'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final dailyJson =
        (json['daily'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final hourlyJson =
        (json['hourly'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final dailyTimes = _asStringList(dailyJson['time']);
    final dailyCodes = _asNumList(dailyJson['weather_code']);
    final dailyMaxTemps = _asNumList(dailyJson['temperature_2m_max']);
    final dailyMinTemps = _asNumList(dailyJson['temperature_2m_min']);
    final dailyRainProb =
        _asNumList(dailyJson['precipitation_probability_max']);
    final dailyWindMax = _asNumList(dailyJson['wind_speed_10m_max']);
    final dailyWindDir =
        _asNumList(dailyJson['wind_direction_10m_dominant']);

    final dailyCount = [
      dailyTimes.length,
      dailyMaxTemps.length,
      dailyMinTemps.length,
    ].reduce((a, b) => a < b ? a : b);

    final dailyList = List<DailyForecast>.generate(dailyCount, (i) {
      return DailyForecast(
        date: DateTime.tryParse(dailyTimes[i]) ??
            DateTime.now().add(Duration(days: i)),
        weatherCode: i < dailyCodes.length ? dailyCodes[i].toInt() : 0,
        temperature2mMax: dailyMaxTemps[i].toDouble(),
        temperature2mMin: dailyMinTemps[i].toDouble(),
        precipitationProbabilityMax:
            i < dailyRainProb.length ? dailyRainProb[i].toInt() : 0,
        windSpeed10mMax:
            i < dailyWindMax.length ? dailyWindMax[i].toDouble() : 0.0,
        windDirection10mDominant:
            i < dailyWindDir.length ? dailyWindDir[i].toInt() : 0,
      );
    });

    final hourlyTimes = _asStringList(hourlyJson['time']);
    final hourlyHumidities = _asNumList(hourlyJson['relative_humidity_2m']);
    final hourlyRainProbs =
        _asNumList(hourlyJson['precipitation_probability']);

    final hourlyCount = hourlyTimes.length;
    final hourlyList = List<HourlyForecastPoint>.generate(hourlyCount, (i) {
      return HourlyForecastPoint(
        time: DateTime.tryParse(hourlyTimes[i]) ?? DateTime.now(),
        relativeHumidity2m:
            i < hourlyHumidities.length ? hourlyHumidities[i].toInt() : 0,
        precipitationProbability:
            i < hourlyRainProbs.length ? hourlyRainProbs[i].toInt() : 0,
      );
    });

    return WeatherModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: (json['timezone'] as String?) ?? 'GMT',
      timezoneAbbreviation: (json['timezone_abbreviation'] as String?) ?? 'GMT',
      current: CurrentWeather.fromJson(currentJson),
      daily: dailyList,
      hourly: hourlyList,
    );
  }

  /// First 24 hours from API hourly stream for today's spline curve.
  List<HourlyForecastPoint> get todayHourlyPoints {
    if (hourly.isEmpty) return const [];
    final count = hourly.length >= 24 ? 24 : hourly.length;
    return hourly.sublist(0, count);
  }

  int get todayPeakRainProbability {
    final points = todayHourlyPoints;
    if (points.isNotEmpty) {
      return points
          .map((e) => e.precipitationProbability)
          .reduce((a, b) => a > b ? a : b);
    }
    if (daily.isNotEmpty) return daily.first.precipitationProbabilityMax;
    return 0;
  }

  String get todayPeakRainTimeLabel {
    final points = todayHourlyPoints;
    if (points.isEmpty) return 'Puncak harian';
    var peak = points.first;
    for (final point in points) {
      if (point.precipitationProbability > peak.precipitationProbability) {
        peak = point;
      }
    }
    final hh = peak.time.hour.toString().padLeft(2, '0');
    return 'Puncak pukul $hh:00';
  }

  int get averageHumidity {
    final points = todayHourlyPoints;
    if (points.isEmpty) return current.relativeHumidity2m;
    final total =
        points.fold<int>(0, (sum, item) => sum + item.relativeHumidity2m);
    return (total / points.length).round();
  }

  double get weeklyMaxWindKmh {
    if (daily.isEmpty) return current.windSpeed10m;
    return daily
        .map((e) => e.windSpeed10mMax)
        .reduce((a, b) => a > b ? a : b);
  }

  String get weeklyMaxWindSubtitle {
    if (daily.isEmpty) {
      return WeatherFormatter.windStatus(current.windSpeed10m);
    }
    var peakDay = daily.first;
    for (final day in daily) {
      if (day.windSpeed10mMax > peakDay.windSpeed10mMax) {
        peakDay = day;
      }
    }
    final dir =
        WeatherFormatter.compassDirection(peakDay.windDirection10mDominant);
    final label = WeatherFormatter.windStatus(peakDay.windSpeed10mMax);
    return '$dir · $label';
  }

  double averageMaxTemp(int days) {
    final slice = daily.take(days).toList();
    if (slice.isEmpty) return current.temperature2m;
    final sum =
        slice.fold<double>(0.0, (acc, d) => acc + d.temperature2mMax);
    return sum / slice.length;
  }

  int averageRainChance(int days) {
    final slice = daily.take(days).toList();
    if (slice.isEmpty) return 0;
    final sum = slice.fold<int>(
        0, (acc, d) => acc + d.precipitationProbabilityMax);
    return (sum / slice.length).round();
  }

  static List<String> _asStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).toList();
  }

  static List<num> _asNumList(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map((e) => (e as num?) ?? 0).toList();
  }
}
