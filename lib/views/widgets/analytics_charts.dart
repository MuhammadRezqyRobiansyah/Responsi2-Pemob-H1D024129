import 'dart:math' as math;

import 'package:aethercast/core/theme/app_theme.dart';
import 'package:aethercast/views/widgets/smooth_tap.dart';
import 'package:flutter/material.dart';

/// Data point passed into [WeeklyBarChart].
class BarChartEntry {
  const BarChartEntry({
    required this.label,
    required this.value,
    required this.formattedValue,
  });

  final String label;
  final double value;
  final String formattedValue;
}

/// Interactive vertical frosted bar chart matching Screen 3's design.
/// The selected bar highlights in deep forest teal with its inner value label.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.entries,
    required this.selectedIndex,
    required this.onSelectBar,
  });

  final List<BarChartEntry> entries;
  final int selectedIndex;
  final ValueChanged<int> onSelectBar;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox(height: 150);
    }

    final maxVal = entries.map((e) => e.value).reduce(math.max);
    final minVal = entries.map((e) => e.value).reduce(math.min);
    final span = (maxVal - minVal).abs();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: SizedBox(
        height: 154,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(entries.length, (i) {
            final entry = entries[i];
            final isSelected = i == selectedIndex;
            final normalized = span < 0.01
                ? 0.72
                : 0.42 + ((entry.value - minVal) / span) * 0.58;
            final barHeight = (110.0 * normalized).clamp(42.0, 118.0);

            return Expanded(
              child: SmoothTap(
                pressedScale: 0.93,
                onTap: () => onSelectBar(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      height: barHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppTheme.deepForestTeal,
                                  Color(0xFF0A2A2C),
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.78),
                                  Colors.white.withValues(alpha: 0.34),
                                ],
                              ),
                      ),
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 8),
                      child: isSelected
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: Text(
                                  entry.formattedValue,
                                  style: const TextStyle(
                                    color: AppTheme.textOnDark,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Smooth spline area chart representing today's hourly rain probability curve.
class RainProbabilityAreaChart extends StatelessWidget {
  const RainProbabilityAreaChart({super.key, required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RainSplinePainter(values: values),
      child: const SizedBox(height: 112, width: double.infinity),
    );
  }
}

class _RainSplinePainter extends CustomPainter {
  const _RainSplinePainter({required this.values});

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;

    // Sample up to 9 evenly spaced points for a sleek smooth wave
    final sampled = _downsample(values, 9);
    final maxVal = math.max(sampled.reduce(math.max), 20).toDouble();

    final points = <Offset>[];
    final stepX = sampled.length > 1
        ? size.width / (sampled.length - 1)
        : size.width;
    var peakIndex = 0;

    for (var i = 0; i < sampled.length; i++) {
      if (sampled[i] > sampled[peakIndex]) {
        peakIndex = i;
      }
      final x = i * stepX;
      final ratio = (sampled[i] / maxVal).clamp(0.05, 1.0);
      final y = size.height - (ratio * size.height * 0.72) - size.height * 0.12;
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final areaPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.deepForestTeal.withValues(alpha: 0.45),
          AppTheme.deepForestTeal.withValues(alpha: 0.03),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, fillPaint);

    final strokePaint = Paint()
      ..color = AppTheme.deepForestTeal
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, strokePaint);

    final peak = points[peakIndex];
    final outerDot = Paint()..color = Colors.white;
    final innerDot = Paint()..color = AppTheme.deepForestTeal;
    canvas.drawCircle(peak, 5.2, outerDot);
    canvas.drawCircle(peak, 3.0, innerDot);
  }

  List<int> _downsample(List<int> source, int targetCount) {
    if (source.length <= targetCount) return source;
    final result = <int>[];
    for (var i = 0; i < targetCount; i++) {
      final idx = ((i * (source.length - 1)) / (targetCount - 1)).round();
      result.add(source[idx]);
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _RainSplinePainter oldDelegate) {
    if (oldDelegate.values.length != values.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
    }
    return false;
  }
}
