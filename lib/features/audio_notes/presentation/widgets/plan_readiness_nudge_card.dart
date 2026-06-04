import 'package:flutter/material.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/audio_notes/presentation/cubit/plan_readiness_home_cubit.dart';
import 'package:sample/features/audio_notes/presentation/widgets/plan_readiness_indicator.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

class PlanReadinessNudgeCard extends StatelessWidget {
  const PlanReadinessNudgeCard({
    super.key,
    required this.nudge,
    required this.onTap,
  });

  final PlanReadinessNudge nudge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Material(
      color: t.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
            border: Border.all(color: t.ghostBorder(0.12)),
          ),
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.planReadinessHomeTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: t.primary,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PlanReadinessIndicator(
                readiness: nudge.readiness,
                compact: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.planReadinessHomeBody(
                  nudge.noteTitle.trim().isEmpty
                      ? l10n.planReadinessUntitledNote
                      : nudge.noteTitle,
                  nudge.readiness.percent,
                  nudge.readiness.gapCount,
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: t.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
