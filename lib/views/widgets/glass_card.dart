import 'dart:ui';

import 'package:aethercast/core/theme/app_theme.dart';
import 'package:aethercast/views/widgets/smooth_tap.dart';
import 'package:flutter/material.dart';

/// Wadah kaca buram (frosted glassmorphism) dengan backdrop blur, isi transparan,
/// border 1px, serta animasi tekan halus saat [onTap] disediakan.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppTheme.cardRadius,
    this.topAlpha = 0.38,
    this.bottomAlpha = 0.24,
    this.borderAlpha = 0.42,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double topAlpha;
  final double bottomAlpha;
  final double borderAlpha;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: AppTheme.glassDecoration(
        radius: radius,
        topAlpha: topAlpha,
        bottomAlpha: bottomAlpha,
        borderAlpha: borderAlpha,
      ),
      child: child,
    );

    final glass = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppTheme.glassBlurSigma,
          sigmaY: AppTheme.glassBlurSigma,
        ),
        child: onTap == null
            ? content
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(radius),
                  splashColor: Colors.white.withValues(alpha: 0.18),
                  highlightColor: Colors.white.withValues(alpha: 0.08),
                  onTap: onTap,
                  child: content,
                ),
              ),
      ),
    );

    if (onTap == null) return glass;
    return SmoothTap(
      onTap: onTap,
      pressedScale: 0.975,
      child: glass,
    );
  }
}

/// Tombol ikon kaca berbentuk lingkaran dengan efek tekan membal yang halus.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor = AppTheme.textPrimary,
    this.size = 40,
    this.iconSize = 20,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final double size;
  final double iconSize;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = SmoothTap(
      onTap: onTap,
      pressedScale: 0.88,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.42),
                  Colors.white.withValues(alpha: 0.22),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
