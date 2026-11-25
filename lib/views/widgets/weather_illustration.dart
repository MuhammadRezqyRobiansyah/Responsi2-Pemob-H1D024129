import 'package:aethercast/core/theme/app_theme.dart';
import 'package:aethercast/core/utils/weather_code_mapper.dart';
import 'package:flutter/material.dart';

/// Custom-painted hero weather illustration matching the soft layered 3D feel
/// of the UI reference while reacting dynamically to WMO weather codes.
class WeatherIllustration extends StatelessWidget {
  const WeatherIllustration({
    super.key,
    required this.kind,
    this.isDay = true,
    this.size = 92,
  });

  final WeatherKind kind;
  final bool isDay;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WeatherIllustrationPainter(kind: kind, isDay: isDay),
      ),
    );
  }
}

class _WeatherIllustrationPainter extends CustomPainter {
  const _WeatherIllustrationPainter({required this.kind, required this.isDay});

  final WeatherKind kind;
  final bool isDay;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (kind) {
      case WeatherKind.clear:
        if (isDay) {
          _drawSun(canvas, Offset(w * 0.5, h * 0.5), w * 0.30);
        } else {
          _drawMoon(canvas, Offset(w * 0.5, h * 0.5), w * 0.28);
        }
      case WeatherKind.partlyCloudy:
        if (isDay) {
          _drawSun(canvas, Offset(w * 0.62, h * 0.34), w * 0.22);
        } else {
          _drawMoon(canvas, Offset(w * 0.62, h * 0.34), w * 0.20);
        }
        _drawCloud(canvas, w, h, offsetY: 0.08);
      case WeatherKind.cloudy:
        _drawCloud(canvas, w, h, offsetY: -0.05, tint: const Color(0xFFDCE5E4));
        _drawCloud(canvas, w, h, offsetY: 0.08, scale: 0.92);
      case WeatherKind.fog:
        _drawCloud(canvas, w, h, offsetY: -0.04, scale: 0.9);
        _drawFogLines(canvas, w, h);
      case WeatherKind.drizzle:
      case WeatherKind.rain:
        _drawCloud(canvas, w, h, offsetY: -0.04, tint: const Color(0xFFE4ECEB));
        _drawRainDrops(canvas, w, h, heavy: kind == WeatherKind.rain);
      case WeatherKind.thunderstorm:
        _drawCloud(canvas, w, h, offsetY: -0.05, tint: const Color(0xFFD0DCDB));
        _drawLightning(canvas, w, h);
      case WeatherKind.snow:
        _drawCloud(canvas, w, h, offsetY: -0.04);
        _drawSnowflakes(canvas, w, h);
    }
  }

  void _drawSun(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.warmAmber.withValues(alpha: 0.40),
          AppTheme.warmAmber.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.65));
    canvas.drawCircle(center, radius * 1.65, glowPaint);

    final sunPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFFFCD34D), AppTheme.warmAmber],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sunPaint);
  }

  void _drawMoon(Canvas canvas, Offset center, double radius) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE2E8F0).withValues(alpha: 0.35),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.6));
    canvas.drawCircle(center, radius * 1.6, glowPaint);

    final moonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF8FAFC), Color(0xFFCBD5E1)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    final cutout = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(center.dx + radius * 0.42, center.dy - radius * 0.25),
          radius: radius * 0.85,
        ),
      );
    final crescent = Path.combine(PathOperation.difference, path, cutout);
    canvas.drawPath(crescent, moonPaint);
  }

  void _drawCloud(
    Canvas canvas,
    double w,
    double h, {
    double offsetY = 0.0,
    double scale = 1.0,
    Color tint = Colors.white,
  }) {
    canvas.save();
    canvas.translate(w * 0.5, h * (0.56 + offsetY));
    canvas.scale(scale);
    canvas.translate(-w * 0.5, -h * 0.56);

    final cloudPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.14, h * 0.48, w * 0.68, h * 0.26),
          Radius.circular(h * 0.13),
        ),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.38, h * 0.48), radius: w * 0.17),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(w * 0.57, h * 0.44), radius: w * 0.19),
      );

    final shadowPaint = Paint()
      ..color = AppTheme.bgDeepShadow.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(cloudPath.shift(const Offset(0, 5)), shadowPaint);

    final cloudPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [tint, const Color(0xFFE7EEED)],
      ).createShader(Rect.fromLTWH(w * 0.14, h * 0.25, w * 0.70, h * 0.50));
    canvas.drawPath(cloudPath, cloudPaint);
    canvas.restore();
  }

  void _drawRainDrops(Canvas canvas, double w, double h, {required bool heavy}) {
    final paint = Paint()
      ..color = AppTheme.softSkyBlue
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final xs = heavy ? [0.28, 0.43, 0.58, 0.70] : [0.34, 0.50, 0.64];
    for (var i = 0; i < xs.length; i++) {
      final startX = w * xs[i];
      final startY = h * (i.isEven ? 0.77 : 0.80);
      canvas.drawLine(
        Offset(startX, startY),
        Offset(startX - 4, startY + 10),
        paint,
      );
    }
  }

  void _drawLightning(Canvas canvas, double w, double h) {
    final bolt = Path()
      ..moveTo(w * 0.52, h * 0.66)
      ..lineTo(w * 0.43, h * 0.80)
      ..lineTo(w * 0.51, h * 0.80)
      ..lineTo(w * 0.45, h * 0.94)
      ..lineTo(w * 0.60, h * 0.76)
      ..lineTo(w * 0.52, h * 0.76)
      ..close();

    final paint = Paint()..color = AppTheme.warmAmber;
    canvas.drawPath(bolt, paint);
  }

  void _drawFogLines(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.22, h * 0.78),
      Offset(w * 0.76, h * 0.78),
      paint,
    );
    canvas.drawLine(
      Offset(w * 0.30, h * 0.87),
      Offset(w * 0.68, h * 0.87),
      paint,
    );
  }

  void _drawSnowflakes(Canvas canvas, double w, double h) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.95);
    for (final offset in [
      Offset(w * 0.33, h * 0.82),
      Offset(w * 0.50, h * 0.86),
      Offset(w * 0.66, h * 0.81),
    ]) {
      canvas.drawCircle(offset, 3.3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherIllustrationPainter oldDelegate) {
    return oldDelegate.kind != kind || oldDelegate.isDay != isDay;
  }
}
