import 'package:flutter/material.dart';

import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/app_section_header.dart';
import 'package:sample/features/audio_notes/domain/utils/plan_snapshot_diff.dart';
import 'package:sample/features/audio_notes/presentation/utils/plan_snapshot_field_labels.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

/// Field-level thesis diff after a debrief. No section borders or list lines.
class ThesisFieldDiffSection extends StatelessWidget {
  const ThesisFieldDiffSection({
    super.key,
    required this.diff,
    this.diffSummary,
  });

  final PlanSnapshotDiff diff;
  final String? diffSummary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;
    final theme = Theme.of(context);
    final summary = diffSummary?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          eyebrow: l10n.thesisResultEyebrow,
          title: l10n.thesisDiffTitle,
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
        ),
        if (summary != null && summary.isNotEmpty) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.primaryContainer,
              borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                summary,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: t.primary,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (diff.isEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.thesisDiffEmpty,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: t.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          )
        else
          for (var i = 0; i < diff.changes.length; i++) ...[
            _FieldChangeCard(change: diff.changes[i]),
            if (i < diff.changes.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _FieldChangeCard extends StatelessWidget {
  const _FieldChangeCard({required this.change});

  final PlanSnapshotFieldChange change;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;
    final theme = Theme.of(context);
    final before = change.before?.trim();

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
              planSnapshotFieldLabel(l10n, change.fieldKey),
              style: theme.textTheme.labelLarge?.copyWith(
                color: t.primary,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (change.isNew) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.thesisDiffNew,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: t.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ] else if (before != null && before.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.thesisDiffWas,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: t.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                before,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: t.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              change.after,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
