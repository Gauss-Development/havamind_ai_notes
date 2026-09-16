import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/thesis/domain/utils/thesis_snapshot_diff.dart';

void main() {
  group('thesisSnapshotAsPlanSnapshot', () {
    test('remaps title onto startup_title', () {
      final plan = thesisSnapshotAsPlanSnapshot({
        'title': 'Havamind',
        'problem': 'Capture is too slow',
      });

      expect(plan['startup_title'], 'Havamind');
      expect(plan['problem'], 'Capture is too slow');
    });
  });

  group('diffThesisSnapshots', () {
    test('treats empty previous as new populated fields', () {
      final diff = diffThesisSnapshots(
        previous: null,
        current: {
          'title': 'Havamind',
          'problem': 'Founders lose the thread after a call',
        },
      );

      expect(diff.isEmpty, isFalse);
      expect(diff.changes.map((c) => c.fieldKey), contains('startup_title'));
      expect(diff.changes.map((c) => c.fieldKey), contains('problem'));
      expect(diff.changes.every((c) => c.isNew), isTrue);
    });

    test('reuses plan snapshot diff for changed fields', () {
      final diff = diffThesisSnapshots(
        previous: {'title': 'Old', 'problem': 'Old pain'},
        current: {'title': 'Old', 'problem': 'New pain'},
      );

      expect(diff.changes, hasLength(1));
      expect(diff.changes.first.fieldKey, 'problem');
      expect(diff.changes.first.before, 'Old pain');
      expect(diff.changes.first.after, 'New pain');
      expect(diff.changes.first.isNew, isFalse);
    });
  });
}
