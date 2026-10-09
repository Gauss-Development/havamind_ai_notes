import 'package:flutter/material.dart';

import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/app_section_header.dart';
import 'package:sample/features/audio_notes/presentation/utils/plan_snapshot_field_labels.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

/// Current speech. Empty fields are omitted — they are gone, not appended.
class ThesisSpeechSection extends StatelessWidget {
  const ThesisSpeechSection({
    super.key,
    required this.thesis,
    this.rewriteNote,
  });

  final Thesis thesis;
  final String? rewriteNote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fields = <(String, String)>[
      ('short_summary', thesis.shortSummary ?? ''),
      ('problem', thesis.problem ?? ''),
      ('solution', thesis.solution ?? ''),
      ('target_audience', thesis.targetAudience ?? ''),
      ('business_model', thesis.businessModel ?? ''),
      ('key_metrics', thesis.keyMetrics ?? ''),
      ('advantages', thesis.advantages ?? ''),
      ('risks_gaps', thesis.risksGaps ?? ''),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          eyebrow: l10n.thesisCurrentSpeechEyebrow,
          title: l10n.thesisCurrentSpeechTitle,
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
        ),
        if (rewriteNote != null && rewriteNote!.trim().isNotEmpty) ...[
          Text(
            rewriteNote!.trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.appTokens.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        for (final field in fields)
          if (field.$2.trim().isNotEmpty)
            _SpeechParagraph(
              label: planSnapshotFieldLabel(l10n, field.$1),
              text: field.$2.trim(),
            ),
      ],
    );
  }
}

/// Heard speeches. The text is read-only and has no correct-this-speech action.
class ThesisHeardVersionsSection extends StatelessWidget {
  const ThesisHeardVersionsSection({super.key, required this.versions});

  final List<ThesisVersion> versions;

  @override
  Widget build(BuildContext context) {
    final heard = versions.where((version) => version.wasHeard).toList();
    if (heard.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          eyebrow: l10n.thesisHeardVersionsEyebrow,
          title: l10n.thesisHeardVersionsTitle,
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
        ),
        for (final version in heard) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.surfaceContainer,
              borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.thesisHeardBy(version.heardByLabel!.trim()),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _snapshotSpeech(version.thesisSnapshot),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  String _snapshotSpeech(Map<String, dynamic> snapshot) {
    const keys = [
      'title',
      'short_summary',
      'problem',
      'solution',
      'target_audience',
      'business_model',
      'key_metrics',
      'advantages',
      'risks_gaps',
    ];
    final lines = <String>[];
    for (final key in keys) {
      final value = snapshot[key];
      if (value is! String) continue;
      final text = value.trim();
      if (text.isEmpty) continue;
      lines.add(text);
    }
    return lines.join('\n\n');
  }
}

class _SpeechParagraph extends StatelessWidget {
  const _SpeechParagraph({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.appTokens;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: t.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(text, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4)),
        ],
      ),
    );
  }
}
