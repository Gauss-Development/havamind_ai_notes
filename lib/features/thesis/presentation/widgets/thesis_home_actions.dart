import 'package:flutter/material.dart';

import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/app_gradient_card.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

/// Primary debrief (or first-run pitch) CTA plus secondary Home actions.
class ThesisHomeActions extends StatelessWidget {
  const ThesisHomeActions({
    super.key,
    required this.isBlankThesis,
    required this.onDebrief,
    required this.onColdPitch,
  });

  final bool isBlankThesis;
  final VoidCallback onDebrief;
  final VoidCallback onColdPitch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;
    final theme = Theme.of(context);

    final primaryIsPitch = isBlankThesis;
    final primaryOnTap = primaryIsPitch ? onColdPitch : onDebrief;
    final headline = primaryIsPitch
        ? l10n.thesisColdPitchCta
        : l10n.thesisDebriefCta;
    final body = primaryIsPitch
        ? l10n.thesisColdPitchBody
        : l10n.thesisDebriefBody;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppGradientCard(
          onTap: primaryOnTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: t.onPrimaryButton,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: t.onPrimaryButton.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.onPrimaryButton.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic_rounded,
                  color: t.onPrimaryButton,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            if (!primaryIsPitch)
              Expanded(
                child: AppGradientButton(
                  onPressed: onColdPitch,
                  label: l10n.thesisColdPitchAction,
                  icon: Icons.campaign_outlined,
                  variant: AppButtonVariant.outlined,
                  expand: true,
                ),
              )
            else
              Expanded(
                child: AppGradientButton(
                  onPressed: onDebrief,
                  label: l10n.thesisDebriefAction,
                  icon: Icons.record_voice_over_outlined,
                  variant: AppButtonVariant.outlined,
                  expand: true,
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Tooltip(
                message: l10n.thesisCollectWeekSoon,
                child: AppGradientButton(
                  onPressed: null,
                  label: l10n.thesisCollectWeekAction,
                  icon: Icons.calendar_view_week_outlined,
                  variant: AppButtonVariant.outlined,
                  expand: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
