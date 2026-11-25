import 'package:aethercast/core/constants/api_constants.dart';
import 'package:aethercast/models/location_model.dart';
import 'package:aethercast/models/weather_model.dart';
import 'package:aethercast/services/local_storage_service.dart';
import 'package:aethercast/services/weather_api_service.dart';
import 'package:flutter/foundation.dart';

/// UI states for city search via Open-Meteo Geocoding API.
enum SearchLoadState { idle, loading, loaded, empty, error }

/// ViewModel managing Geocoding city search, saved favorite locations,
/// live weather previews for favorites, and persistent search history.
class LocationViewModel extends ChangeNotifier {
  LocationViewModel({
    required this._apiService,
    required this._storageService,
  });

  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  SearchLoadState _searchState = SearchLoadState.idle;
  List<LocationModel> _searchResults = const [];
  String _lastQuery = '';
  String? _searchErrorMessage;

  List<LocationModel> _favorites = [];
  final Map<String, CurrentWeather> _favoriteWeatherMap = {};
  final Set<String> _loadingFavoriteKeys = {};
  List<LocationModel> _recentSearches = [];

  int _searchRequestToken = 0;

  SearchLoadState get searchState => _searchState;
  List<LocationModel> get searchResults => List.unmodifiable(_searchResults);
  String get lastQuery => _lastQuery;
  String? get searchErrorMessage => _searchErrorMessage;
  List<LocationModel> get favorites => List.unmodifiable(_favorites);
  List<LocationModel> get recentSearches => List.unmodifiable(_recentSearches);

  CurrentWeather? weatherForFavorite(LocationModel location) =>
      _favoriteWeatherMap[location.locationKey];

  bool isLoadingFavoriteWeather(LocationModel location) =>
      _loadingFavoriteKeys.contains(location.locationKey);

  bool isFavorite(LocationModel location) =>
      _favorites.any((item) => item.locationKey == location.locationKey);

  /// Loads favorites and recent searches from [SharedPreferences] on startup.
  Future<void> initialize() async {
    _favorites = await _storageService.getFavorites();
    _recentSearches = await _storageService.getRecentSearches();
    notifyListeners();

    if (_favorites.isNotEmpty) {
      await refreshFavoriteWeathers();
    }
  }

  /// Queries Open-Meteo Geocoding API by city name.
  Future<void> searchCities(String query) async {
    final trimmed = query.trim();
    _lastQuery = trimmed;

    if (trimmed.isEmpty) {
      _searchRequestToken++;
      _searchResults = const [];
      _searchErrorMessage = null;
      _searchState = SearchLoadState.idle;
      notifyListeners();
      return;
    }

    final requestToken = ++_searchRequestToken;
    _searchState = SearchLoadState.loading;
    _searchErrorMessage = null;
    notifyListeners();

    try {
      final results = await _apiService.searchLocations(trimmed);
      if (requestToken != _searchRequestToken) return;

      _searchResults = results;
      _searchState =
          results.isEmpty ? SearchLoadState.empty : SearchLoadState.loaded;
    } on WeatherApiException catch (e) {
      if (requestToken != _searchRequestToken) return;
      _searchResults = const [];
      _searchErrorMessage = e.message;
      _searchState = SearchLoadState.error;
    } catch (_) {
      if (requestToken != _searchRequestToken) return;
      _searchResults = const [];
      _searchErrorMessage = 'Tidak dapat mencari kota saat ini.';
      _searchState = SearchLoadState.error;
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchRequestToken++;
    _lastQuery = '';
    _searchResults = const [];
    _searchErrorMessage = null;
    _searchState = SearchLoadState.idle;
    notifyListeners();
  }

  /// Adds or removes [location] from favorites and persists locally.
  /// Returns `true` if added, `false` if removed.
  Future<bool> toggleFavorite(LocationModel location) async {
    final existingIndex = _favorites
        .indexWhere((item) => item.locationKey == location.locationKey);

    if (existingIndex >= 0) {
      _favorites.removeAt(existingIndex);
      _favoriteWeatherMap.remove(location.locationKey);
      notifyListeners();
      await _storageService.saveFavorites(_favorites);
      return false;
    }

    _favorites.insert(0, location);
    notifyListeners();
    await _storageService.saveFavorites(_favorites);
    await _fetchSingleFavoriteWeather(location);
    return true;
  }

  /// Saves a selected city to persistent recent search chips.
  Future<void> addRecentSearch(LocationModel location) async {
    _recentSearches
        .removeWhere((item) => item.locationKey == location.locationKey);
    _recentSearches.insert(0, location);
    if (_recentSearches.length > ApiConstants.maxRecentSearches) {
      _recentSearches =
          _recentSearches.sublist(0, ApiConstants.maxRecentSearches);
    }
    notifyListeners();
    await _storageService.saveRecentSearches(_recentSearches);
  }

  Future<void> clearRecentSearches() async {
    _recentSearches = [];
    notifyListeners();
    await _storageService.clearRecentSearches();
  }

  Future<void> refreshFavoriteWeathers() async {
    if (_favorites.isEmpty) return;
    await Future.wait(_favorites.map(_fetchSingleFavoriteWeather));
  }

  Future<void> _fetchSingleFavoriteWeather(LocationModel location) async {
    final key = location.locationKey;
    _loadingFavoriteKeys.add(key);
    notifyListeners();

    try {
      final snapshot = await _apiService.fetchCurrentSnapshot(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      _favoriteWeatherMap[key] = snapshot;
    } catch (_) {
      // Keep existing snapshot or omit live temp quietly on partial failure.
    } finally {
      _loadingFavoriteKeys.remove(key);
      notifyListeners();
    }
  }
}
