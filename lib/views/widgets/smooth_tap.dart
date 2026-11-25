import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Memberikan efek tekan membal (scale + opacity + haptic ringan)
/// pada setiap tombol atau kartu agar interaksi terasa lebih halus.
class SmoothTap extends StatefulWidget {
  const SmoothTap({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.96,
    this.enableHaptics = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool enableHaptics;

  @override
  State<SmoothTap> createState() => _SmoothTapState();
}

class _SmoothTapState extends State<SmoothTap> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.enableHaptics) {
                HapticFeedback.selectionClick();
              }
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _isPressed ? widget.pressedScale : 1.0,
        duration: Duration(milliseconds: _isPressed ? 105 : 220),
        curve: _isPressed ? Curves.easeOutCubic : Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.86 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: widget.child,
        ),
      ),
    );
  }
}
