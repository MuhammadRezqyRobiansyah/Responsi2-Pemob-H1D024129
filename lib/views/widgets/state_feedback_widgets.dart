import 'package:aethercast/core/theme/app_theme.dart';
import 'package:aethercast/views/widgets/glass_card.dart';
import 'package:aethercast/views/widgets/smooth_tap.dart';
import 'package:flutter/material.dart';

/// Tampilan loading kaca buram saat mengambil data langsung dari Open-Meteo.
class LoadingWeatherView extends StatelessWidget {
  const LoadingWeatherView({
    super.key,
    this.message = 'Memuat data cuaca terkini...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
          child: Column(
            children: [
              const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppTheme.deepForestTeal,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Menghubungkan ke Open-Meteo API',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: _ShimmerBlock(height: 112)),
            SizedBox(width: 10),
            Expanded(child: _ShimmerBlock(height: 112)),
            SizedBox(width: 10),
            Expanded(child: _ShimmerBlock(height: 112)),
          ],
        ),
        const SizedBox(height: 16),
        const _ShimmerBlock(height: 220),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      topAlpha: 0.25,
      bottomAlpha: 0.14,
      child: SizedBox(height: height),
    );
  }
}

/// Kartu status kosong saat hasil pencarian atau daftar tersimpan masih kosong.
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.45),
            ),
            child: Icon(icon, color: AppTheme.deepForestTeal, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            SmoothTap(
              onTap: onAction,
              child: FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.deepForestTeal,
                  foregroundColor: AppTheme.textOnDark,
                  shape: const StadiumBorder(),
                ),
                child: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kartu error kaca buram dengan tombol Coba Lagi yang responsif.
class ErrorStateCard extends StatelessWidget {
  const ErrorStateCard({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Gagal memuat cuaca',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.dangerCoral.withValues(alpha: 0.16),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppTheme.deepForestTeal,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SmoothTap(
            onTap: onRetry,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.deepForestTeal,
                foregroundColor: AppTheme.textOnDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
