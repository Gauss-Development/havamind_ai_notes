import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/audio_notes/domain/utils/analysis_plan_gaps.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

/// Circular progress + copy for plan section completeness.
class PlanReadinessIndicator extends StatelessWidget {
  const PlanReadinessIndicator({
    super.key,
    required this.readiness,
    this.compact = false,
    this.title,
    this.completeLabel,
  });

  final PlanReadiness readiness;
  final bool compact;

  /// Overrides the default "PLAN READINESS" eyebrow (Home thesis card).
  final String? title;

  /// Overrides the all-sections-complete line.
  final String? completeLabel;

  static const double _ringSize = 64;
  static const double _compactRingSize = 48;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.obsidian;
    final theme = Theme.of(context);
    final ringSize = compact ? _compactRingSize : _ringSize;
    final progressColor = _progressColor(
      t,
      theme.colorScheme,
      readiness.percent,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: ringSize,
          height: ringSize,
          child: CustomPaint(
            painter: _PlanReadinessRingPainter(
              ratio: readiness.ratio,
              trackColor: t.outlineVariant.withValues(alpha: 0.18),
              progressColor: progressColor,
              strokeWidth: compact ? 4.5 : 5.5,
            ),
            child: Center(
              child: Text(
                l10n.planReadinessPercent(readiness.percent),
                style:
                    (compact
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: progressColor,
                        ),
              ),
            ),
          ),
        ),
        SizedBox(width: compact ? AppSpacing.sm : AppSpacing.base),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? l10n.planReadinessTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.6,
                  color: t.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                readiness.isComplete
                    ? (completeLabel ?? l10n.planReadinessComplete)
                    : l10n.planReadinessSections(
                        readiness.completedCount,
                        readiness.totalCount,
                      ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!compact && !readiness.isComplete) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.planReadinessHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: t.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Color _progressColor(
    ObsidianUiTokens t,
    ColorScheme colorScheme,
    int percent,
  ) {
    if (percent >= 100) return t.secondary;
    if (percent >= 75) return t.primary;
    if (percent >= 50) return t.warning;
    return colorScheme.error.withValues(alpha: 0.85);
  }
}

class _PlanReadinessRingPainter extends CustomPainter {
  _PlanReadinessRingPainter({
    required this.ratio,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double ratio;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * ratio.clamp(0.0, 1.0);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (ratio > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
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
  bool shouldRepaint(_PlanReadinessRingPainter oldDelegate) =>
      ratio != oldDelegate.ratio ||
      trackColor != oldDelegate.trackColor ||
      progressColor != oldDelegate.progressColor ||
      strokeWidth != oldDelegate.strokeWidth;
}
