import 'package:flutter/material.dart';
import 'package:sample/features/audio_notes/presentation/pages/recording_page.dart';
import 'package:sample/features/audio_notes/presentation/pages/recording_prep_onboarding_page.dart';
import 'package:sample/features/audio_notes/presentation/utils/recording_onboarding_prefs.dart';

/// Opens recording. Pass [templateId] to skip the onboarding template picker
/// (Home debrief / cold pitch). Notes-tab FAB still uses the picker path.
///
/// Returns the saved audio note on success, `false` when cancelled, or
/// `true` from the onboarding path that still pops a boolean.
Future<Object?> openRecordingFlow(
  BuildContext context, {
  String? templateId,
  String? voicePrompt,
}) async {
  if (templateId != null) {
    return Navigator.of(context).push<Object>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RecordingPage(
          initialTemplateId: templateId,
          voicePrompt: voicePrompt,
        ),
      ),
    );
  }

  final completed = await RecordingOnboardingPrefs.isCompleted();
  if (!context.mounted) return null;

  if (completed) {
    return Navigator.of(context).push<Object>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RecordingPage(voicePrompt: voicePrompt),
      ),
    );
  }

  return Navigator.of(context).push<Object>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const RecordingPrepOnboardingPage(),
    ),
  );
}
