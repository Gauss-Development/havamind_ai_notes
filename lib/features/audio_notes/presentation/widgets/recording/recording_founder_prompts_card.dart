import 'package:flutter/material.dart';
import 'package:sample/core/di/injection.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _dismissKeyForTemplate(String templateId) =>
    'recording_guide_dismissed_${RecordingTemplateIds.normalize(templateId)}';

/// Rotating seconds between highlighted prompts while recording.
const _kPromptRotationSeconds = 15;

/// Idle checklist shows this many topics before expanding.
const _kCollapsedPromptCount = 2;

class FounderRecordingPrompt {
  const FounderRecordingPrompt({
    required this.icon,
    required this.title,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String hint;
}

List<FounderRecordingPrompt> recordingPromptsForTemplate(
  AppLocalizations l10n,
  String templateId,
) {
  switch (RecordingTemplateIds.normalize(templateId)) {
    case RecordingTemplateIds.customerDiscovery:
      return customerDiscoveryRecordingPrompts(l10n);
    case RecordingTemplateIds.investorUpdate:
      return investorUpdateRecordingPrompts(l10n);
    case RecordingTemplateIds.founderPitch:
    default:
      return founderRecordingPrompts(l10n);
  }
}

({String title, String subtitle}) recordingGuideForTemplate(
  AppLocalizations l10n,
  String templateId,
) {
  switch (RecordingTemplateIds.normalize(templateId)) {
    case RecordingTemplateIds.customerDiscovery:
      return (
        title: l10n.customerDiscoveryGuideTitle,
        subtitle: l10n.customerDiscoveryGuideSubtitle,
      );
    case RecordingTemplateIds.investorUpdate:
      return (
        title: l10n.investorUpdateGuideTitle,
        subtitle: l10n.investorUpdateGuideSubtitle,
      );
    case RecordingTemplateIds.founderPitch:
    default:
      return (
        title: l10n.founderPitchGuideTitle,
        subtitle: l10n.founderPitchGuideSubtitle,
      );
  }
}

List<FounderRecordingPrompt> founderRecordingPrompts(AppLocalizations l10n) {
  return [
    FounderRecordingPrompt(
      icon: Icons.bolt_rounded,
      title: l10n.founderPromptProblemTitle,
      hint: l10n.founderPromptProblemHint,
    ),
    FounderRecordingPrompt(
      icon: Icons.groups_rounded,
      title: l10n.founderPromptAudienceTitle,
      hint: l10n.founderPromptAudienceHint,
    ),
    FounderRecordingPrompt(
      icon: Icons.lightbulb_outline_rounded,
      title: l10n.founderPromptSolutionTitle,
      hint: l10n.founderPromptSolutionHint,
    ),
    FounderRecordingPrompt(
      icon: Icons.payments_outlined,
      title: l10n.founderPromptMonetizationTitle,
      hint: l10n.founderPromptMonetizationHint,
    ),
    FounderRecordingPrompt(
      icon: Icons.rocket_launch_outlined,
      title: l10n.founderPromptTractionTitle,
      hint: l10n.founderPromptTractionHint,
    ),
  ];
}

List<FounderRecordingPrompt> customerDiscoveryRecordingPrompts(
  AppLocalizations l10n,
) {
  return [
    FounderRecordingPrompt(
      icon: Icons.route_outlined,
      title: l10n.customerDiscoveryPromptWorkflowTitle,
      hint: l10n.customerDiscoveryPromptWorkflowHint,
    ),
    FounderRecordingPrompt(
      icon: Icons.local_fire_department_outlined,
      title: l10n.customerDiscoveryPromptPainTitle,
      hint: l10n.customerDiscoveryPromptPainHint,
    ),
    FounderRecordingPrompt(
      icon: Icons.record_voice_over_outlined,
      title: l10n.customerDiscoveryPromptSubjectTitle,
      hint: l10n.customerDiscoveryPromptSubjectHint,
    ),
    FounderRecordingPrompt(
      icon: Icons.lightbulb_outline_rounded,
      title: l10n.customerDiscoveryPromptInsightTitle,
      hint: l10n.customerDiscoveryPromptInsightHint,
    ),
    FounderRecordingPrompt(
      icon: Icons.person_search_outlined,
      title: l10n.customerDiscoveryPromptNextTitle,
      hint: l10n.customerDiscoveryPromptNextHint,
    ),
  ];
}

List<FounderRecordingPrompt> investorUpdateRecordingPrompts(
  AppLocalizations l10n,
) {
  return [
    FounderRecordingPrompt(
      icon: Icons.star_outline_rounded,
      title: l10n.investorUpdatePromptHighlightsTitle,
      hint: l10n.investorUpdatePromptHighlightsHint,
    ),
    FounderRecordingPrompt(
      icon: Icons.show_chart_outlined,
      title: l10n.investorUpdatePromptMetricsTitle,
      hint: l10n.investorUpdatePromptMetricsHint,
    ),
    FounderRecordingPrompt(
      icon: Icons.inventory_2_outlined,
      title: l10n.investorUpdatePromptProductTitle,
      hint: l10n.investorUpdatePromptProductHint,
    ),
    FounderRecordingPrompt(
      icon: Icons.warning_amber_rounded,
      title: l10n.investorUpdatePromptChallengesTitle,
      hint: l10n.investorUpdatePromptChallengesHint,
    ),
    FounderRecordingPrompt(
      icon: Icons.help_outline_rounded,
      title: l10n.investorUpdatePromptAskTitle,
      hint: l10n.investorUpdatePromptAskHint,
    ),
  ];
}

/// Pre-record checklist and in-record prompt rotation for voice memos.
class RecordingFounderPromptsCard extends StatefulWidget {
  const RecordingFounderPromptsCard({
    super.key,
    required this.templateId,
    required this.isRecording,
    required this.elapsedSeconds,
    this.compactLayout = false,
    this.overlayLayout = false,
    this.onboardingMode = false,
  });

  final String templateId;
  final bool isRecording;
  final int elapsedSeconds;
  final bool compactLayout;
  final bool overlayLayout;
  final bool onboardingMode;

  @override
  State<RecordingFounderPromptsCard> createState() =>
      _RecordingFounderPromptsCardState();
}

class _RecordingFounderPromptsCardState
    extends State<RecordingFounderPromptsCard> {
  bool _visible = true;
  bool _showAllPrompts = false;
  String? _loadedTemplateId;

  @override
  void initState() {
    super.initState();
    if (widget.onboardingMode) {
      _showAllPrompts = true;
    } else {
      _loadDismissed();
    }
  }

  @override
  void didUpdateWidget(covariant RecordingFounderPromptsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.templateId != widget.templateId) {
      _visible = true;
      _showAllPrompts = widget.onboardingMode;
      if (!widget.onboardingMode) {
        _loadDismissed();
      }
    }
  }

  Future<void> _loadDismissed() async {
    final templateId = RecordingTemplateIds.normalize(widget.templateId);
    _loadedTemplateId = templateId;
    final prefs = getIt<SharedPreferences>();
    final dismissed =
        prefs.getBool(_dismissKeyForTemplate(templateId)) ?? false;
    if (dismissed && mounted && _loadedTemplateId == templateId) {
      setState(() => _visible = false);
    }
  }

  Future<void> _dismiss() async {
    final templateId = RecordingTemplateIds.normalize(widget.templateId);
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool(_dismissKeyForTemplate(templateId), true);
    if (mounted) setState(() => _visible = false);
  }

  int _activeIndex(List<FounderRecordingPrompt> prompts) {
    if (prompts.isEmpty) return 0;
    final step = widget.elapsedSeconds ~/ _kPromptRotationSeconds;
    return step % prompts.length;
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final templateId = RecordingTemplateIds.normalize(widget.templateId);
    final prompts = recordingPromptsForTemplate(l10n, templateId);
    final guide = recordingGuideForTemplate(l10n, templateId);
    final t = context.appTokens;
    final theme = Theme.of(context);

    if (widget.isRecording) {
      final prompt = prompts[_activeIndex(prompts)];
      return Padding(
        padding: widget.overlayLayout
            ? EdgeInsets.zero
            : const EdgeInsets.only(bottom: AppSpacing.md),
        child: _PromptBanner(
          tokens: t,
          theme: theme,
          icon: prompt.icon,
          title: l10n.tryCoveringTitle(prompt.title),
          subtitle: prompt.hint,
          compact: true,
        ),
      );
    }

    final cardPadding = widget.compactLayout ? AppSpacing.sm : AppSpacing.base;
    final visiblePrompts = widget.onboardingMode || _showAllPrompts
        ? prompts
        : prompts.take(_kCollapsedPromptCount).toList();
    final canExpand =
        !widget.onboardingMode && prompts.length > _kCollapsedPromptCount;

    return Padding(
      padding: widget.overlayLayout
          ? EdgeInsets.zero
          : EdgeInsets.only(
              top: widget.compactLayout ? AppSpacing.xs : AppSpacing.sm,
              bottom: AppSpacing.md,
            ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: t.surfaceContainerLow,
          borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.record_voice_over_outlined,
                  size: widget.compactLayout ? 18 : 20,
                  color: t.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guide.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!widget.compactLayout) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          guide.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: t.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!widget.onboardingMode)
                  IconButton(
                    onPressed: _dismiss,
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: l10n.hideGuide,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            SizedBox(
              height: widget.compactLayout ? AppSpacing.sm : AppSpacing.md,
            ),
            ...visiblePrompts.map(
              (prompt) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(prompt.icon, size: 18, color: t.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: t.onSurface,
                            height: 1.35,
                          ),
                          children: [
                            TextSpan(
                              text: '${prompt.title}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: prompt.hint,
                              style: TextStyle(color: t.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (canExpand)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () =>
                      setState(() => _showAllPrompts = !_showAllPrompts),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    _showAllPrompts
                        ? l10n.recordingGuideShowLess
                        : l10n.recordingGuideShowAllTopics,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PromptBanner extends StatelessWidget {
  const _PromptBanner({
    required this.tokens,
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final AppTokens tokens;
  final ThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: Container(
        key: ValueKey(title),
        width: double.infinity,
        padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.base),
        decoration: BoxDecoration(
          color: tokens.primaryContainer,
          borderRadius: BorderRadius.circular(ObsidianUiTokens.radiusMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: tokens.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: tokens.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.primary.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
