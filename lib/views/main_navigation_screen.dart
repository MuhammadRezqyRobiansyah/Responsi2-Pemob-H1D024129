import 'package:aethercast/core/theme/app_theme.dart';
import 'package:aethercast/views/analytics/forecast_analytics_screen.dart';
import 'package:aethercast/views/home/home_weather_screen.dart';
import 'package:aethercast/views/search/search_location_screen.dart';
import 'package:aethercast/views/settings/settings_screen.dart';
import 'package:aethercast/views/widgets/atmospheric_background.dart';
import 'package:aethercast/views/widgets/smooth_tap.dart';
import 'package:flutter/material.dart';

/// Kerangka navigasi utama dengan transisi antar-tab halus
/// dan Fluid Floating Pill Bottom Navigation Bar.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _setTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeWeatherScreen(
        onSeeAllForecast: () => _setTab(2),
        onOpenSearch: () => _setTab(1),
      ),
      SearchLocationScreen(
        onLocationSelected: () => _setTab(0),
      ),
      ForecastAnalyticsScreen(
        onBackToHome: () => _setTab(0),
      ),
      SettingsScreen(
        onEditLocation: () => _setTab(1),
      ),
    ];

    return Scaffold(
      body: AtmosphericBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: List.generate(screens.length, (i) {
                        final active = i == _currentIndex;
                        return AnimatedOpacity(
                          opacity: active ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          child: AnimatedScale(
                            scale: active ? 1.0 : 0.985,
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            child: screens[i],
                          ),
                        );
                      }),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 18,
                    child: SafeArea(
                      top: false,
                      child: _FluidPillNavBar(
                        currentIndex: _currentIndex,
                        onTap: _setTab,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fluid Bottom Navbar: kapsul putih meluncur mulus dengan efek pendar cahaya
/// dan animasi skala ikon ketika berpindah antar tab.
class _FluidPillNavBar extends StatelessWidget {
  const _FluidPillNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItemData(label: 'Beranda', icon: Icons.home_rounded),
    _NavItemData(label: 'Cari', icon: Icons.search_rounded),
    _NavItemData(label: 'Analitik', icon: Icons.bar_chart_rounded),
    _NavItemData(label: 'Pengaturan', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.navPillDark,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.bgDeepShadow.withValues(alpha: 0.45),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final slotUnit = totalWidth / 5;
          final activeWidth = slotUnit * 2;
          final inactiveWidth = slotUnit;

          return Stack(
            children: [
              // Lapisan 1: Kapsul putih fluid yang meluncur mulus mengikuti tab aktif
              AnimatedPositioned(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeInOutCubicEmphasized,
                left: currentIndex * slotUnit,
                width: activeWidth,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.30),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // Lapisan 2: Keempat tombol tab yang menyelaraskan posisi secara fluid
              ...List.generate(_items.length, (i) {
                final item = _items[i];
                final active = i == currentIndex;
                final left = i <= currentIndex
                    ? i * slotUnit
                    : (i - 1) * slotUnit + activeWidth;
                final width = active ? activeWidth : inactiveWidth;

                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeInOutCubicEmphasized,
                  left: left,
                  width: width,
                  top: 0,
                  bottom: 0,
                  child: SmoothTap(
                    pressedScale: 0.90,
                    onTap: () => onTap(i),
                    child: Center(
                      child: active
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedScale(
                                      scale: 1.08,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOutBack,
                                      child: Icon(
                                        item.icon,
                                        size: 20,
                                        color: AppTheme.navPillDark,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    AnimatedOpacity(
                                      opacity: 1.0,
                                      duration:
                                          const Duration(milliseconds: 240),
                                      child: Text(
                                        item.label,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.navPillDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 0.8,
                                ),
                              ),
                              child: Icon(
                                item.icon,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
