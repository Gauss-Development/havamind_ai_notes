import 'package:flutter/material.dart';
import 'package:sample/features/audio_notes/presentation/pages/recording_page.dart';
import 'package:sample/features/audio_notes/presentation/pages/recording_prep_onboarding_page.dart';
import 'package:sample/features/audio_notes/presentation/utils/recording_onboarding_prefs.dart';

/// Opens recording. Pass [templateId] to skip the onboarding template picker
/// (Home debrief / cold pitch). Notes-tab FAB still uses the picker path.
Future<bool?> openRecordingFlow(
  BuildContext context, {
  String? templateId,
}) async {
  if (templateId != null) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => RecordingPage(initialTemplateId: templateId),
      ),
    );
  }

  final completed = await RecordingOnboardingPrefs.isCompleted();
  if (!context.mounted) return null;

  if (completed) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const RecordingPage(),
      ),
    );
  }

  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const RecordingPrepOnboardingPage(),
    ),
  );
}
