import 'package:flutter/material.dart';

import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/app_section_header.dart';
import 'package:sample/features/audio_notes/presentation/utils/plan_snapshot_field_labels.dart';
import 'package:sample/features/thesis/domain/utils/thesis_readiness.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

/// Unbacked thesis stakes with the same voice-reply gesture as plan gaps.
class ThesisUnbackedStakesCard extends StatelessWidget {
  const ThesisUnbackedStakesCard({
    super.key,
    required this.stakes,
    required this.onAnswerByVoice,
  });

  final List<ThesisUnbackedGap> stakes;
  final void Function(String fieldKey, String question) onAnswerByVoice;

  @override
  Widget build(BuildContext context) {
    if (stakes.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.thesisUnbackedTitle,
          subtitle: l10n.thesisUnbackedHint,
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
        ),
        for (var i = 0; i < stakes.length; i++) ...[
          _UnbackedStakeRow(
            fieldKey: stakes[i].fieldKey,
            onAnswer: () {
              final label = planSnapshotFieldLabel(l10n, stakes[i].fieldKey);
              onAnswerByVoice(
                stakes[i].fieldKey,
                l10n.thesisUnbackedVoiceQuestion(label),
              );
            },
          ),
          if (i < stakes.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _UnbackedStakeRow extends StatelessWidget {
  const _UnbackedStakeRow({required this.fieldKey, required this.onAnswer});

  final String fieldKey;
  final VoidCallback onAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, size: 18, color: t.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                planSnapshotFieldLabel(l10n, fieldKey),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ),
            IconButton(
              onPressed: onAnswer,
              icon: Icon(Icons.mic_rounded, size: 20, color: t.primary),
              tooltip: l10n.answerByVoice,
            ),
          ],
        ),
      ),
    );
  }
}
