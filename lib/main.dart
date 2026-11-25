import 'package:aethercast/core/theme/app_theme.dart';
import 'package:aethercast/services/local_storage_service.dart';
import 'package:aethercast/services/weather_api_service.dart';
import 'package:aethercast/viewmodels/location_viewmodel.dart';
import 'package:aethercast/viewmodels/weather_viewmodel.dart';
import 'package:aethercast/views/main_navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AetherCastApp());
}

/// Root widget configuring MVVM ViewModels via [MultiProvider] and [AppTheme].
class AetherCastApp extends StatelessWidget {
  const AetherCastApp({
    super.key,
    this.apiService,
    this.storageService,
  });

  final WeatherApiService? apiService;
  final LocalStorageService? storageService;

  @override
  Widget build(BuildContext context) {
    final resolvedApi = apiService ?? WeatherApiService();
    final resolvedStorage = storageService ?? LocalStorageService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WeatherViewModel>(
          create: (_) => WeatherViewModel(
            apiService: resolvedApi,
            storageService: resolvedStorage,
          )..initialize(),
        ),
        ChangeNotifierProvider<LocationViewModel>(
          create: (_) => LocationViewModel(
            apiService: resolvedApi,
            storageService: resolvedStorage,
          )..initialize(),
        ),
      ],
      child: MaterialApp(
        title: 'AetherCast',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
