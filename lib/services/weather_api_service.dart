import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aethercast/core/constants/api_constants.dart';
import 'package:aethercast/models/location_model.dart';
import 'package:aethercast/models/weather_model.dart';
import 'package:http/http.dart' as http;

/// Thrown when an Open-Meteo HTTP request fails or returns malformed data.
class WeatherApiException implements Exception {
  const WeatherApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Handles HTTP GET calls directly to Open-Meteo Forecast & Geocoding APIs.
class WeatherApiService {
  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Searches global cities by name via Open-Meteo Geocoding API.
  Future<List<LocationModel>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse(ApiConstants.geocodingBaseUrl).replace(
      queryParameters: {
        'name': trimmed,
        'count': ApiConstants.geocodingMaxResults.toString(),
        'language': 'id',
        'format': 'json',
      },
    );

    final jsonMap = await _getJson(uri);
    final rawResults = jsonMap['results'];
    if (rawResults is! List || rawResults.isEmpty) {
      return const [];
    }

    return rawResults
        .whereType<Map<String, dynamic>>()
        .map(LocationModel.fromGeocodingJson)
        .toList();
  }

  /// Fetches full current, hourly, and 7-day daily weather for coordinates.
  Future<WeatherModel> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(ApiConstants.weatherForecastBaseUrl).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day',
        'hourly': 'relative_humidity_2m,precipitation_probability',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,wind_direction_10m_dominant',
        'timezone': 'auto',
        'forecast_days': ApiConstants.forecastDays.toString(),
      },
    );

    final jsonMap = await _getJson(uri);
    return WeatherModel.fromJson(jsonMap);
  }

  /// Lightweight current-only snapshot used to display live temperatures on saved favorites.
  Future<CurrentWeather> fetchCurrentSnapshot({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(ApiConstants.weatherForecastBaseUrl).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day',
        'timezone': 'auto',
      },
    );

    final jsonMap = await _getJson(uri);
    final currentJson = jsonMap['current'];
    if (currentJson is! Map<String, dynamic>) {
      throw const WeatherApiException(
        'Respons cuaca dari Open-Meteo tidak sesuai format.',
      );
    }
    return CurrentWeather.fromJson(currentJson);
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response =
          await _client.get(uri).timeout(ApiConstants.requestTimeout);
      if (response.statusCode != 200) {
        throw WeatherApiException(
          'Server mengembalikan status HTTP ${response.statusCode}. Silakan coba lagi.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const WeatherApiException(
          'Format JSON dari layanan cuaca tidak valid.',
        );
      }
      if (decoded['error'] == true) {
        final reason =
            decoded['reason']?.toString() ?? 'Terjadi kesalahan pada API';
        throw WeatherApiException(reason);
      }
      return decoded;
    } on TimeoutException {
      throw const WeatherApiException(
        'Koneksi habis waktu. Periksa jaringan internet Anda.',
      );
    } on SocketException {
      throw const WeatherApiException(
        'Tidak ada koneksi internet. Gagal menjangkau Open-Meteo.',
      );
    } on http.ClientException {
      throw const WeatherApiException(
        'Terjadi gangguan jaringan saat mengambil data cuaca.',
      );
    } on FormatException {
      throw const WeatherApiException(
        'Gagal membaca respons JSON dari Open-Meteo.',
      );
    }
  }
}
