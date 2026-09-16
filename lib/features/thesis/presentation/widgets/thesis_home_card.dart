import 'package:flutter/material.dart';

import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/app_icon_chip.dart';
import 'package:sample/features/audio_notes/presentation/utils/plan_snapshot_field_labels.dart';
import 'package:sample/features/audio_notes/presentation/widgets/plan_readiness_indicator.dart';
import 'package:sample/features/thesis/domain/utils/thesis_readiness.dart';
import 'package:sample/features/thesis/presentation/cubit/thesis_home_cubit.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

/// Account thesis on Home: title, readiness, and up to two unbacked gaps.
class ThesisHomeCard extends StatelessWidget {
  const ThesisHomeCard({super.key, required this.loaded});

  final ThesisHomeLoaded loaded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;
    final theme = Theme.of(context);
    final title = loaded.thesis.title?.trim();
    final displayTitle = (title == null || title.isEmpty)
        ? l10n.thesisUntitled
        : title;
    final planReadiness = thesisReadinessAsPlanReadiness(loaded.readiness);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.thesisLivingEyebrow,
              style: theme.textTheme.labelLarge?.copyWith(
                color: t.primary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              displayTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            if (loaded.thesis.shortSummary?.trim().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                loaded.thesis.shortSummary!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: t.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ] else if (loaded.isBlank) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.thesisLivingSlogan,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: t.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            PlanReadinessIndicator(
              readiness: planReadiness,
              compact: true,
              title: l10n.thesisReadinessTitle,
              completeLabel: l10n.thesisReadinessComplete,
            ),
            if (loaded.unbackedGaps.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.thesisUnbackedGapsLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: t.onSurfaceVariant,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final gap in loaded.unbackedGaps)
                    AppIconChip(
                      icon: Icons.flag_outlined,
                      label: planSnapshotFieldLabel(l10n, gap.fieldKey),
                      tone: AppIconChipTone.warning,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
