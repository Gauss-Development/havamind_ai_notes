import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';
import 'package:sample/features/subscription/domain/entities/usage_info.dart';

class UsageCircularIndicator extends StatelessWidget {
  const UsageCircularIndicator({super.key, required this.usageInfo});

  final UsageInfo usageInfo;

  static const double _ringSize = 76;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final ringColor = _ringColor(t, theme.colorScheme);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: t.surfaceContainerHigh.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
          border: Border.all(
            color: t.outlineVariant.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _ringSize,
              height: _ringSize,
              child: CustomPaint(
                painter: _RingPainter(
                  ratio: usageInfo.usageRatio,
                  trackColor: t.outlineVariant.withValues(alpha: 0.18),
                  progressColor: ringColor,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${usageInfo.remainingMinutes}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: ringColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'min left',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: t.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usage',
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 0.6,
                      color: t.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${usageInfo.usedMinutes} of ${usageInfo.limitMinutes} min',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _subtitleText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: t.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _subtitleText {
    if (usageInfo.isExhausted) {
      return 'Quota used for this period — upgrade for more recording time.';
    }
    final tierLabel = switch (usageInfo.tier) {
      SubscriptionTier.free => 'Free',
      SubscriptionTier.basic => 'Basic',
      SubscriptionTier.pro => 'Pro',
    };
    final remain = usageInfo.remainingMinutes;
    final s = remain == 1 ? '' : 's';
    return '$tierLabel plan · $remain minute$s remaining this period';
  }

  Color _ringColor(ObsidianUiTokens t, ColorScheme colorScheme) {
    final ratio = usageInfo.usageRatio;
    if (ratio >= 1.0) return colorScheme.error;
    if (ratio >= 0.85) return t.warning;
    if (ratio >= 0.55) return t.secondary;
    return t.primary;
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.ratio,
    required this.trackColor,
    required this.progressColor,
  });

  final double ratio;
  final Color trackColor;
  final Color progressColor;

  static const double _strokeWidth = 5.5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - _strokeWidth) / 2;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * ratio.clamp(0.0, 1.0);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (ratio > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      ratio != oldDelegate.ratio ||
      trackColor != oldDelegate.trackColor ||
      progressColor != oldDelegate.progressColor;
}
