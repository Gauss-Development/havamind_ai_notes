import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/audio_notes/domain/utils/plan_snapshot_diff.dart';

void main() {
  group('diffPlanSnapshots', () {
    test('returns empty when previous is null', () {
      final diff = diffPlanSnapshots(
        previous: null,
        current: {'problem': 'Pain'},
      );
      expect(diff.isEmpty, isTrue);
    });

    test('returns empty when previous is empty', () {
      final diff = diffPlanSnapshots(
        previous: {},
        current: {'problem': 'Pain'},
      );
      expect(diff.isEmpty, isTrue);
    });

    test('detects changed text fields', () {
      final diff = diffPlanSnapshots(
        previous: {'problem': 'Old pain', 'solution': 'Same'},
        current: {'problem': 'New pain', 'solution': 'Same'},
      );

      expect(diff.changes, hasLength(1));
      expect(diff.changes.first.fieldKey, 'problem');
      expect(diff.changes.first.before, 'Old pain');
      expect(diff.changes.first.after, 'New pain');
      expect(diff.changes.first.isNew, isFalse);
    });

    test('detects new fields as isNew', () {
      final diff = diffPlanSnapshots(
        previous: {'problem': 'Pain'},
        current: {'problem': 'Pain', 'solution': 'Fix it'},
      );

      expect(diff.changes, hasLength(1));
      expect(diff.changes.first.fieldKey, 'solution');
      expect(diff.changes.first.isNew, isTrue);
      expect(diff.changes.first.before, isNull);
    });

    test('normalizes numeric scores to percent strings', () {
      final diff = diffPlanSnapshots(
        previous: {'market_potential_score': 40},
        current: {'market_potential_score': 72},
      );

      expect(diff.changes, hasLength(1));
      expect(diff.changes.first.before, '40%');
      expect(diff.changes.first.after, '72%');
    });

    test('ignores removals when after is empty', () {
      final diff = diffPlanSnapshots(
        previous: {'problem': 'Was here'},
        current: {'problem': ''},
      );

      expect(diff.isEmpty, isTrue);
    });
  });
}
