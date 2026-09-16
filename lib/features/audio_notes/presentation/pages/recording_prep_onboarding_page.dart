import 'package:flutter/material.dart';
import 'package:sample/core/theme/app_spacing.dart';
import 'package:sample/core/theme/obsidian_ui_tokens.dart';
import 'package:sample/core/widgets/obsidian_gradient_button.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/audio_notes/presentation/pages/recording_page.dart';
import 'package:sample/features/audio_notes/presentation/utils/recording_onboarding_prefs.dart';
import 'package:sample/features/audio_notes/presentation/widgets/recording/recording_founder_prompts_card.dart';
import 'package:sample/features/audio_notes/presentation/widgets/recording/recording_template_picker.dart';
import 'package:sample/l10n/generated/app_localizations.dart';

class RecordingPrepOnboardingPage extends StatefulWidget {
  const RecordingPrepOnboardingPage({super.key});

  @override
  State<RecordingPrepOnboardingPage> createState() =>
      _RecordingPrepOnboardingPageState();
}

class _RecordingPrepOnboardingPageState
    extends State<RecordingPrepOnboardingPage> {
  String _selectedTemplateId = RecordingTemplateIds.founderPitch;

  Future<void> _finishAndOpenRecording(BuildContext context) async {
    await RecordingOnboardingPrefs.markCompleted();
    if (!context.mounted) return;

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<Object>(
        fullscreenDialog: true,
        builder: (_) => RecordingPage(initialTemplateId: _selectedTemplateId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.appTokens;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: t.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(false),
          icon: const Icon(Icons.close_rounded),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        ),
        title: Text(
          l10n.recordingOnboardingTitle,
          style: theme.textTheme.titleMedium,
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _finishAndOpenRecording(context),
            child: Text(l10n.recordingOnboardingSkip),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.recordingOnboardingSubtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: t.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.recordingOnboardingTemplateLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: t.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    RecordingTemplatePicker(
                      selectedId: _selectedTemplateId,
                      onSelected: (id) {
                        setState(() => _selectedTemplateId = id);
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    RecordingFounderPromptsCard(
                      templateId: _selectedTemplateId,
                      isRecording: false,
                      elapsedSeconds: 0,
                      onboardingMode: true,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              child: ObsidianGradientButton(
                onPressed: () => _finishAndOpenRecording(context),
                label: l10n.recordingOnboardingContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
