import 'package:flutter/material.dart';

import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/app_section_header.dart';
import 'package:sample/features/thesis/domain/entities/next_conversation_script.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

/// Who / hypothesis / what not to ask after a debrief.
class ThesisNextConversationCard extends StatelessWidget {
  const ThesisNextConversationCard({super.key, required this.script});

  final NextConversationScript script;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;
    final theme = Theme.of(context);

    final blocks = <({String eyebrow, String body})>[
      if (_has(script.who))
        (eyebrow: l10n.thesisNextWho, body: script.who!.trim()),
      if (_has(script.hypothesis))
        (eyebrow: l10n.thesisNextHypothesis, body: script.hypothesis!.trim()),
      if (_has(script.doNotAsk))
        (eyebrow: l10n.thesisNextDoNotAsk, body: script.doNotAsk!.trim()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.thesisNextConversationTitle,
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: t.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusXl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: blocks.isEmpty
                ? Text(
                    l10n.thesisNextEmpty,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: t.onSurfaceVariant,
                      height: 1.4,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < blocks.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.lg),
                        Text(
                          blocks[i].eyebrow,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: t.primary,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          blocks[i].body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  static bool _has(String? value) => value != null && value.trim().isNotEmpty;
}
