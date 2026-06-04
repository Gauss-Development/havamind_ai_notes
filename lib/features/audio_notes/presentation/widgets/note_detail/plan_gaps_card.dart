import 'package:flutter/material.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/audio_notes/domain/utils/analysis_plan_gaps.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

/// Highlights missing plan sections and offers one-tap voice follow-up.
class PlanGapsCard extends StatelessWidget {
  const PlanGapsCard({
    super.key,
    required this.gaps,
    required this.onAnswerByVoice,
  });

  final List<AnalysisPlanGap> gaps;
  final void Function(StartupAnalysisEditableField field, String question)
      onAnswerByVoice;

  @override
  Widget build(BuildContext context) {
    if (gaps.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: t.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        border: Border.all(color: t.ghostBorder(0.12)),
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.playlist_add_check_rounded, size: 18, color: t.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.planGapsTitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: t.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.planGapsHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: t.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < gaps.length; i++) ...[
            _PlanGapRow(
              label: _fieldLabel(l10n, gaps[i].field),
              onAnswer: () => onAnswerByVoice(
                gaps[i].field,
                _voiceQuestion(l10n, gaps[i].field),
              ),
            ),
            if (i < gaps.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }

  static String _fieldLabel(
    AppLocalizations l10n,
    StartupAnalysisEditableField field,
  ) {
    return switch (field) {
      StartupAnalysisEditableField.problem => l10n.theProblem,
      StartupAnalysisEditableField.solution => l10n.theSolution,
      StartupAnalysisEditableField.targetAudience => l10n.targetAudience,
      StartupAnalysisEditableField.businessModel => l10n.businessModel,
      StartupAnalysisEditableField.keyMetrics => l10n.keyMetrics,
      StartupAnalysisEditableField.advantages => l10n.advantages,
      StartupAnalysisEditableField.risksGaps => l10n.risksAndGaps,
      StartupAnalysisEditableField.shortSummary => l10n.summary,
      StartupAnalysisEditableField.startupTitle => l10n.note,
    };
  }

  static String _voiceQuestion(
    AppLocalizations l10n,
    StartupAnalysisEditableField field,
  ) {
    return switch (field) {
      StartupAnalysisEditableField.problem => l10n.planGapAskProblem,
      StartupAnalysisEditableField.solution => l10n.planGapAskSolution,
      StartupAnalysisEditableField.targetAudience => l10n.planGapAskTargetAudience,
      StartupAnalysisEditableField.businessModel => l10n.planGapAskBusinessModel,
      StartupAnalysisEditableField.keyMetrics => l10n.planGapAskKeyMetrics,
      StartupAnalysisEditableField.advantages => l10n.planGapAskAdvantages,
      StartupAnalysisEditableField.risksGaps => l10n.planGapAskRisksGaps,
      StartupAnalysisEditableField.shortSummary => l10n.planGapAskShortSummary,
      StartupAnalysisEditableField.startupTitle => l10n.planGapAskStartupTitle,
    };
  }
}

class _PlanGapRow extends StatelessWidget {
  const _PlanGapRow({
    required this.label,
    required this.onAnswer,
  });

  final String label;
  final VoidCallback onAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.obsidian;
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.radio_button_unchecked_rounded, size: 16, color: t.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: t.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
        IconButton(
          onPressed: onAnswer,
          icon: Icon(Icons.mic_rounded, size: 18, color: t.primary),
          tooltip: l10n.answerByVoice,
        ),
      ],
    );
  }
}
