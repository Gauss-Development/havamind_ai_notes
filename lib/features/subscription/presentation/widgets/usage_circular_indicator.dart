import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';
import 'package:sample/features/subscription/domain/entities/usage_info.dart';

class UsageCircularIndicator extends StatelessWidget {
  const UsageCircularIndicator({super.key, required this.usageInfo});

  final UsageInfo usageInfo;

  @override
  Widget build(BuildContext context) {
    final t = context.obsidian;
    final theme = Theme.of(context);
    final ringColor = _ringColor(t);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(
              painter: _RingPainter(
                ratio: usageInfo.usageRatio,
                trackColor: t.outlineVariant.withValues(alpha: 0.15),
                progressColor: ringColor,
              ),
              child: Center(
                child: Text(
                  '${usageInfo.remainingMinutes}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ringColor,
                  ),
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
                  '${usageInfo.usedMinutes} / ${usageInfo.limitMinutes} min used',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitleText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: t.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _subtitleText {
    if (usageInfo.isExhausted) {
      return 'Limit reached — upgrade for more';
    }
    final tierLabel = switch (usageInfo.tier) {
      SubscriptionTier.free => 'Free plan',
      SubscriptionTier.basic => 'Basic plan',
      SubscriptionTier.pro => 'Pro plan',
    };
    return '$tierLabel · ${usageInfo.remainingMinutes} min remaining';
  }

  Color _ringColor(ObsidianUiTokens t) {
    final ratio = usageInfo.usageRatio;
    if (ratio >= 1.0) return Colors.redAccent;
    if (ratio >= 0.8) return t.warning;
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

  static const double _strokeWidth = 5.0;

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
