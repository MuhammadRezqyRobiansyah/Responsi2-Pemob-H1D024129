import 'package:aethercast/models/location_model.dart';

/// Base endpoints, storage keys, and startup fallback location metadata.
class ApiConstants {
  ApiConstants._();

  static const String weatherForecastBaseUrl =
      'https://api.open-meteo.com/v1/forecast';
  static const String geocodingBaseUrl =
      'https://geocoding-api.open-meteo.com/v1/search';

  static const Duration requestTimeout = Duration(seconds: 15);
  static const int forecastDays = 7;
  static const int geocodingMaxResults = 10;
  static const int maxRecentSearches = 8;

  /// Initial coordinate fallback when no saved location exists yet.
  /// Weather values are always fetched live from Open-Meteo on startup.
  static const LocationModel defaultLocation = LocationModel(
    id: 1621177,
    name: 'Yogyakarta',
    latitude: -7.7956,
    longitude: 110.3695,
    country: 'Indonesia',
    countryCode: 'ID',
    admin1: 'Special Region of Yogyakarta',
    timezone: 'Asia/Jakarta',
  );
}

/// Keys used by [SharedPreferences] to persist user data locally.
class StorageKeys {
  StorageKeys._();

  static const String favoriteLocations = 'aethercast_favorite_locations';
  static const String recentSearches = 'aethercast_recent_searches';
  static const String lastLocation = 'aethercast_last_location';
  static const String useFahrenheit = 'aethercast_use_fahrenheit';
  static const String windSpeedUnit = 'aethercast_wind_speed_unit';
}
