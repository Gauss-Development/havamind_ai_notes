import 'package:sample/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class RecordingOnboardingPrefs {
  static const _completedKey = 'recording_onboarding_completed';

  static Future<bool> isCompleted() async {
    final prefs = getIt<SharedPreferences>();
    return prefs.getBool(_completedKey) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = getIt<SharedPreferences>();
    await prefs.setBool(_completedKey, true);
  }
}
