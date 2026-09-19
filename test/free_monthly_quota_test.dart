import 'package:flutter_test/flutter_test.dart';
import 'package:sample/core/constants/audio_notes_constants.dart';

void main() {
  test('free monthly quota is 15 minutes so one week-one loop survives', () {
    expect(kFreeMonthlyLimitSeconds, 900);
    expect(kFreeMonthlyLimitSeconds, greaterThan(kDebriefSuggestedDurationSeconds * 4));
    expect(kDebriefSuggestedDurationSeconds, 120);
    expect(kMaxRecordingDurationSeconds, 600);
  });
}
