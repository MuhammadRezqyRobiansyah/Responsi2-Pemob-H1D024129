import 'package:aethercast/core/constants/api_constants.dart';
import 'package:aethercast/core/utils/weather_formatter.dart';
import 'package:aethercast/models/location_model.dart';
import 'package:aethercast/models/weather_model.dart';
import 'package:aethercast/services/local_storage_service.dart';
import 'package:aethercast/services/weather_api_service.dart';
import 'package:flutter/foundation.dart';

/// UI states for weather data loading across Home and Analytics screens.
enum WeatherLoadState { initial, loading, loaded, empty, error }

/// ViewModel managing the active location, live weather forecast,
/// loading/empty/error states, and user unit preferences.
class WeatherViewModel extends ChangeNotifier {
  WeatherViewModel({
    required this._apiService,
    required this._storageService,
  });

  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  WeatherLoadState _state = WeatherLoadState.initial;
  LocationModel _selectedLocation = ApiConstants.defaultLocation;
  WeatherModel? _weather;
  String? _errorMessage;
  bool _useFahrenheit = false;
  WindSpeedUnit _windUnit = WindSpeedUnit.kmh;
  bool _isRefreshing = false;

  WeatherLoadState get state => _state;
  LocationModel get selectedLocation => _selectedLocation;
  WeatherModel? get weather => _weather;
  String? get errorMessage => _errorMessage;
  bool get useFahrenheit => _useFahrenheit;
  WindSpeedUnit get windUnit => _windUnit;
  bool get isRefreshing => _isRefreshing;

  /// Restores user preferences and last active location, then fetches live data.
  Future<void> initialize() async {
    _useFahrenheit = await _storageService.getUseFahrenheit();
    _windUnit = await _storageService.getWindSpeedUnit();
    final savedLocation = await _storageService.getLastLocation();
    if (savedLocation != null) {
      _selectedLocation = savedLocation;
    }
    notifyListeners();
    await fetchWeatherForSelectedLocation();
  }

  /// Switches the active city, persists it locally, and loads fresh weather.
  Future<void> selectLocation(LocationModel location) async {
    _selectedLocation = location;
    _weather = null;
    await _storageService.saveLastLocation(location);
    await fetchWeatherForSelectedLocation();
  }

  /// Fetches live Open-Meteo weather for [_selectedLocation].
  Future<void> fetchWeatherForSelectedLocation({bool pullRefresh = false}) async {
    if (pullRefresh && _weather != null) {
      _isRefreshing = true;
    } else {
      _state = WeatherLoadState.loading;
      _errorMessage = null;
    }
    notifyListeners();

    try {
      final result = await _apiService.fetchWeather(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );
      if (result.daily.isEmpty) {
        _weather = null;
        _state = WeatherLoadState.empty;
      } else {
        _weather = result;
        _state = WeatherLoadState.loaded;
      }
      _errorMessage = null;
    } on WeatherApiException catch (e) {
      _errorMessage = e.message;
      if (_weather == null) {
        _state = WeatherLoadState.error;
      }
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan tak terduga saat memuat data cuaca.';
      if (_weather == null) {
        _state = WeatherLoadState.error;
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> toggleTemperatureUnit(bool fahrenheit) async {
    _useFahrenheit = fahrenheit;
    notifyListeners();
    await _storageService.saveUseFahrenheit(fahrenheit);
  }

  Future<void> setWindUnit(WindSpeedUnit unit) async {
    _windUnit = unit;
    notifyListeners();
    await _storageService.saveWindSpeedUnit(unit);
  }

  String formatTemperature(double celsius, {bool showUnit = true}) {
    return WeatherFormatter.formatTemperature(
      celsius,
      useFahrenheit: _useFahrenheit,
      showUnit: showUnit,
    );
  }

  double convertTemperature(double celsius) {
    return WeatherFormatter.convertTemperature(
      celsius,
      useFahrenheit: _useFahrenheit,
    );
  }

  String formatWind(double kmh) {
    return WeatherFormatter.formatWindSpeed(kmh, unit: _windUnit);
  }

  String get timezoneShortLabel {
    final model = _weather;
    if (model == null) return '--';
    return WeatherFormatter.formatTimezoneShort(
      model.timezone,
      model.timezoneAbbreviation,
    );
  }
}
