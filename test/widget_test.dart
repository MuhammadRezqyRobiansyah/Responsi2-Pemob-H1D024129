import 'dart:convert';

import 'package:aethercast/core/utils/weather_formatter.dart';
import 'package:aethercast/main.dart';
import 'package:aethercast/models/location_model.dart';
import 'package:aethercast/models/weather_model.dart';
import 'package:aethercast/services/local_storage_service.dart';
import 'package:aethercast/services/weather_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _sampleForecastJson({
  double temp = 29.0,
  double apparent = 32.0,
  int humidity = 74,
  double wind = 12.0,
  double precipitation = 0.2,
  int weatherCode = 2,
}) {
  return {
    'latitude': -7.79,
    'longitude': 110.36,
    'timezone': 'Asia/Jakarta',
    'timezone_abbreviation': 'GMT+7',
    'current': {
      'time': '2026-11-25T10:00',
      'temperature_2m': temp,
      'relative_humidity_2m': humidity,
      'apparent_temperature': apparent,
      'precipitation': precipitation,
      'weather_code': weatherCode,
      'wind_speed_10m': wind,
      'is_day': 1,
    },
    'hourly': {
      'time': List.generate(
        24,
        (h) => '2026-11-25T${h.toString().padLeft(2, '0')}:00',
      ),
      'relative_humidity_2m': List.filled(24, humidity),
      'precipitation_probability': List.generate(
        24,
        (h) => h == 16 ? 65 : 20 + (h % 25),
      ),
    },
    'daily': {
      'time': [
        '2026-11-25',
        '2026-11-26',
        '2026-11-27',
        '2026-11-28',
        '2026-11-29',
        '2026-11-30',
        '2026-12-01',
      ],
      'weather_code': [2, 61, 0, 2, 63, 2, 0],
      'temperature_2m_max': [31.0, 28.0, 32.0, 31.0, 29.0, 30.0, 33.0],
      'temperature_2m_min': [24.0, 23.0, 24.0, 25.0, 23.0, 24.0, 25.0],
      'precipitation_probability_max': [40, 75, 10, 25, 60, 35, 15],
      'wind_speed_10m_max': [12.0, 14.0, 10.0, 18.0, 15.0, 11.0, 9.0],
      'wind_direction_10m_dominant': [315, 290, 240, 315, 200, 180, 90],
    },
  };
}

Map<String, dynamic> _sampleGeocodingJson() {
  return {
    'results': [
      {
        'id': 1642911,
        'name': 'Jakarta',
        'latitude': -6.2146,
        'longitude': 106.8451,
        'country': 'Indonesia',
        'country_code': 'ID',
        'admin1': 'Jakarta',
        'timezone': 'Asia/Jakarta',
      },
    ],
  };
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Model & Service unit tests', () {
    test('WeatherModel mem-parsing semua field Open-Meteo current, hourly, dan daily', () {
      final model = WeatherModel.fromJson(_sampleForecastJson());

      expect(model.current.temperature2m, 29.0);
      expect(model.current.apparentTemperature, 32.0);
      expect(model.current.relativeHumidity2m, 74);
      expect(model.current.windSpeed10m, 12.0);
      expect(model.current.precipitation, 0.2);
      expect(model.current.weatherCode, 2);
      expect(model.daily.length, 7);
      expect(model.todayPeakRainProbability, 65);
      expect(model.todayPeakRainTimeLabel, 'Puncak pukul 16:00');
      expect(model.averageHumidity, 74);
      expect(model.weeklyMaxWindKmh, 18.0);
      expect(model.weeklyMaxWindSubtitle, 'BL · Sepoi');
    });

    test('WeatherApiService menjalankan HTTP GET untuk search & forecast serta menangani error', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        if (request.url.host == 'geocoding-api.open-meteo.com') {
          expect(request.url.queryParameters['language'], 'id');
          if (request.url.queryParameters['name'] == 'KotaKosong') {
            return http.Response(jsonEncode({}), 200);
          }
          return http.Response(jsonEncode(_sampleGeocodingJson()), 200);
        }
        if (request.url.queryParameters['latitude'] == '999.0') {
          return http.Response('Server Error', 500);
        }
        return http.Response(jsonEncode(_sampleForecastJson()), 200);
      });

      final api = WeatherApiService(client: client);
      final cities = await api.searchLocations('Jakarta');
      expect(cities.length, 1);
      expect(cities.first.name, 'Jakarta');

      final emptyCities = await api.searchLocations('KotaKosong');
      expect(emptyCities, isEmpty);

      final weather = await api.fetchWeather(latitude: -7.79, longitude: 110.36);
      expect(weather.daily.length, 7);

      expect(
        () => api.fetchWeather(latitude: 999.0, longitude: 0.0),
        throwsA(isA<WeatherApiException>()),
      );
    });

    test('LocalStorageService menyimpan dan memuat favorit, riwayat, serta preferensi satuan', () async {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs: prefs);
      const city = LocationModel(
        id: 1,
        name: 'Bandung',
        latitude: -6.91,
        longitude: 107.61,
        country: 'Indonesia',
        countryCode: 'ID',
      );

      await storage.saveFavorites([city]);
      await storage.saveRecentSearches([city]);
      await storage.saveLastLocation(city);
      await storage.saveUseFahrenheit(true);
      await storage.saveWindSpeedUnit(WindSpeedUnit.mph);

      final loadedFavorites = await storage.getFavorites();
      final loadedRecents = await storage.getRecentSearches();
      final loadedLast = await storage.getLastLocation();

      expect(loadedFavorites.single.name, 'Bandung');
      expect(loadedRecents.single.name, 'Bandung');
      expect(loadedLast?.name, 'Bandung');
      expect(await storage.getUseFahrenheit(), isTrue);
      expect(await storage.getWindSpeedUnit(), WindSpeedUnit.mph);
    });
  });

  group('End-to-end MVVM UI widget tests', () {
    testWidgets('Beranda memuat data live, Cari memilih & memfavoritkan kota, Analitik & Pengaturan berfungsi', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final client = MockClient((request) async {
        if (request.url.host == 'geocoding-api.open-meteo.com') {
          return http.Response(jsonEncode(_sampleGeocodingJson()), 200);
        }
        final lat =
            double.tryParse(request.url.queryParameters['latitude'] ?? '') ?? 0;
        if (lat.round() == -6) {
          return http.Response(
            jsonEncode(_sampleForecastJson(temp: 31.0, apparent: 35.0)),
            200,
          );
        }
        return http.Response(jsonEncode(_sampleForecastJson()), 200);
      });

      final prefs = await SharedPreferences.getInstance();
      final api = WeatherApiService(client: client);
      final storage = LocalStorageService(prefs: prefs);

      await tester.pumpWidget(
        AetherCastApp(apiService: api, storageService: storage),
      );
      await tester.pumpAndSettle();

      // Screen 1: Beranda Cuaca
      expect(find.text('Yogyakarta, ID'), findsOneWidget);
      expect(find.text('29°C'), findsOneWidget);
      expect(find.text('Terasa seperti 32°C'), findsOneWidget);
      expect(find.text('74%'), findsOneWidget);
      expect(find.text('12 km/j'), findsOneWidget);
      expect(find.text('0.2 mm'), findsOneWidget);
      expect(find.text('Prakiraan 7 Hari'), findsOneWidget);

      // Pindah ke Tab Cari via Fluid Navbar
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Lokasi'), findsOneWidget);

      // Cari kota langsung ke Geocoding API
      await tester.enterText(find.byType(TextField), 'Jakarta');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('Hasil Pencarian'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Jakarta'), findsOneWidget);

      // Simpan Jakarta sebagai favorit & pilih Jakarta
      await tester.tap(find.byTooltip('Simpan ke favorit').last);
      await tester.pumpAndSettle();
      expect((await storage.getFavorites()).length, 1);

      await tester.tap(find.widgetWithText(ListTile, 'Jakarta'));
      await tester.pumpAndSettle();

      // Kembali di Beranda dengan Jakarta aktif
      expect(find.text('Jakarta, ID'), findsOneWidget);
      expect(find.text('31°C'), findsOneWidget);

      // Pindah ke Tab Analitik
      await tester.tap(find.byIcon(Icons.bar_chart_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Analitik Prakiraan'), findsOneWidget);
      expect(find.text('Peluang Hujan'), findsNWidgets(2));
      expect(find.text('Angin Maks'), findsOneWidget);
      expect(find.text('Kelembapan Rata-rata'), findsOneWidget);

      await tester.tap(find.text('Peluang Hujan').first);
      await tester.pumpAndSettle();
      expect(find.text('rata hujan'), findsOneWidget);

      // Pindah ke Tab Pengaturan, ubah satuan suhu, angin, & hapus riwayat
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Stasiun Cuaca Aktif'), findsOneWidget);
      expect(find.text('WIB'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(await storage.getUseFahrenheit(), isTrue);

      await tester.tap(find.text('Satuan Angin (km/j)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mil per jam (mph)'));
      await tester.pumpAndSettle();
      expect(await storage.getWindSpeedUnit(), WindSpeedUnit.mph);
      expect(find.text('Satuan Angin (mph)'), findsOneWidget);

      await tester.tap(find.text('Hapus Riwayat Pencarian'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(await storage.getRecentSearches(), isEmpty);

      // Kembali ke Beranda dan pastikan suhu terkonversi ke Fahrenheit
      await tester.tap(find.byIcon(Icons.home_rounded));
      await tester.pumpAndSettle();
      expect(find.text('88°F'), findsOneWidget);
    });

    testWidgets('Menampilkan ErrorStateCard dan pulih melalui tombol Coba Lagi', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var shouldFail = true;
      final client = MockClient((request) async {
        if (shouldFail) {
          return http.Response('Service unavailable', 503);
        }
        return http.Response(jsonEncode(_sampleForecastJson()), 200);
      });

      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        AetherCastApp(
          apiService: WeatherApiService(client: client),
          storageService: LocalStorageService(prefs: prefs),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gagal memuat cuaca'), findsOneWidget);
      expect(find.text('Coba Lagi'), findsOneWidget);

      shouldFail = false;
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();

      expect(find.text('29°C'), findsOneWidget);
    });

    testWidgets('Semua 4 screen & fluid navbar tampil rapi tanpa overflow di layar 360x640', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

        final client = MockClient((request) async {
          return http.Response(
            jsonEncode(_sampleForecastJson(temp: 38.0)),
            200,
          );
        });

        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          AetherCastApp(
            apiService: WeatherApiService(client: client),
            storageService: LocalStorageService(prefs: prefs),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('38°C'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Lokasi'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.bar_chart_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Analitik Prakiraan'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      expect(find.text('Stasiun Cuaca Aktif'), findsOneWidget);
    });
  });
}
