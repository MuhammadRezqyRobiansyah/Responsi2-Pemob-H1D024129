import 'package:aethercast/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Multi-layered misty sage to deep forest teal atmospheric backdrop.
class AtmosphericBackground extends StatelessWidget {
  const AtmosphericBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.bgTopSage,
                AppTheme.bgMidSlate,
                AppTheme.bgBottomTeal,
                AppTheme.bgDeepShadow,
              ],
              stops: [0.0, 0.36, 0.78, 1.0],
            ),
          ),
        ),
        // Soft frosted radial mist behind top hero card
        Positioned(
          top: 90,
          left: -70,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.glowFrost.withValues(alpha: 0.32),
                  AppTheme.glowMist.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Secondary middle mist highlight
        Positioned(
          top: 290,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.glowFrost.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Deep shadow pool near bottom-right matching design reference
        Positioned(
          bottom: 40,
          right: -40,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.bgDeepShadow.withValues(alpha: 0.50),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
