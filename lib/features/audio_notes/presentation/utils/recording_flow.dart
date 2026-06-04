import 'package:flutter/material.dart';
import 'package:sample/features/audio_notes/presentation/pages/recording_page.dart';
import 'package:sample/features/audio_notes/presentation/pages/recording_prep_onboarding_page.dart';
import 'package:sample/features/audio_notes/presentation/utils/recording_onboarding_prefs.dart';

Future<bool?> openRecordingFlow(BuildContext context) async {
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
