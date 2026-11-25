import 'dart:convert';

import 'package:aethercast/core/constants/api_constants.dart';
import 'package:aethercast/core/utils/weather_formatter.dart';
import 'package:aethercast/models/location_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists favorite locations, search history, active city, and unit settings
/// using [SharedPreferences].
class LocalStorageService {
  LocalStorageService({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  SharedPreferences? _cachedPrefs;

  Future<SharedPreferences> get _prefs async {
    if (_prefsOverride != null) return _prefsOverride;
    return _cachedPrefs ??= await SharedPreferences.getInstance();
  }

  Future<List<LocationModel>> getFavorites() async {
    return _readLocationList(StorageKeys.favoriteLocations);
  }

  Future<void> saveFavorites(List<LocationModel> favorites) async {
    await _writeLocationList(StorageKeys.favoriteLocations, favorites);
  }

  Future<List<LocationModel>> getRecentSearches() async {
    return _readLocationList(StorageKeys.recentSearches);
  }

  Future<void> saveRecentSearches(List<LocationModel> recent) async {
    await _writeLocationList(StorageKeys.recentSearches, recent);
  }

  Future<void> clearRecentSearches() async {
    final prefs = await _prefs;
    await prefs.remove(StorageKeys.recentSearches);
  }

  Future<LocationModel?> getLastLocation() async {
    final prefs = await _prefs;
    final raw = prefs.getString(StorageKeys.lastLocation);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        return LocationModel.fromJson(map);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> saveLastLocation(LocationModel location) async {
    final prefs = await _prefs;
    await prefs.setString(
      StorageKeys.lastLocation,
      jsonEncode(location.toJson()),
    );
  }

  Future<bool> getUseFahrenheit() async {
    final prefs = await _prefs;
    return prefs.getBool(StorageKeys.useFahrenheit) ?? false;
  }

  Future<void> saveUseFahrenheit(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(StorageKeys.useFahrenheit, value);
  }

  Future<WindSpeedUnit> getWindSpeedUnit() async {
    final prefs = await _prefs;
    final raw = prefs.getString(StorageKeys.windSpeedUnit);
    return raw == WindSpeedUnit.mph.name
        ? WindSpeedUnit.mph
        : WindSpeedUnit.kmh;
  }

  Future<void> saveWindSpeedUnit(WindSpeedUnit unit) async {
    final prefs = await _prefs;
    await prefs.setString(StorageKeys.windSpeedUnit, unit.name);
  }

  Future<List<LocationModel>> _readLocationList(String key) async {
    final prefs = await _prefs;
    final rawList = prefs.getStringList(key) ?? const [];
    final items = <LocationModel>[];
    for (final raw in rawList) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          items.add(LocationModel.fromJson(decoded));
        }
      } catch (_) {
        // Ignore corrupted entries gracefully.
      }
    }
    return items;
  }

  Future<void> _writeLocationList(String key, List<LocationModel> list) async {
    final prefs = await _prefs;
    final encoded = list.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(key, encoded);
  }
}
