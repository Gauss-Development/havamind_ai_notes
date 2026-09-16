import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_field_evidence.dart';
import 'package:sample/features/thesis/domain/utils/thesis_readiness.dart';

Thesis _thesis({
  String? title,
  String? problem,
  String? solution,
  String? targetAudience,
  String? businessModel,
  String? keyMetrics,
  String? advantages,
  String? risksGaps,
  Map<String, ThesisFieldEvidence> fieldEvidence = const {},
}) {
  return Thesis(
    id: 'thesis-1',
    userId: 'user-1',
    title: title,
    problem: problem,
    solution: solution,
    targetAudience: targetAudience,
    businessModel: businessModel,
    keyMetrics: keyMetrics,
    advantages: advantages,
    risksGaps: risksGaps,
    fieldEvidence: fieldEvidence,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

const _filled = 'Founders lose ideas because capture is too slow to keep.';

void main() {
  group('computeThesisReadiness', () {
    test('scores an empty thesis as 0% with seven gaps', () {
      final readiness = computeThesisReadiness(_thesis());

      expect(readiness.percent, 0);
      expect(readiness.completedCount, 0);
      expect(readiness.gapCount, 7);
      expect(readiness.isBlankThesis(_thesis()), isTrue);
    });

    test('counts only complete core fields', () {
      final thesis = _thesis(
        title: 'Havamind',
        problem: _filled,
        solution: _filled,
      );
      final readiness = computeThesisReadiness(thesis);

      expect(readiness.completedCount, 2);
      expect(readiness.percent, 29);
      expect(readiness.isBlankThesis(thesis), isFalse);
    });
  });

  group('selectThesisUnbackedGaps', () {
    test('prefers evidence-marked unbacked fields over empty ones', () {
      final thesis = _thesis(
        problem: _filled,
        solution: _filled,
        targetAudience: null,
        fieldEvidence: {
          ThesisEvidenceFields.solution: const ThesisFieldEvidence(
            kind: ThesisEvidenceKind.unbacked,
          ),
          ThesisEvidenceFields.problem: const ThesisFieldEvidence(
            kind: ThesisEvidenceKind.founderClaim,
          ),
        },
      );

      final gaps = selectThesisUnbackedGaps(thesis);

      expect(gaps.map((g) => g.fieldKey).toList(), [
        ThesisEvidenceFields.solution,
        ThesisEvidenceFields.targetAudience,
      ]);
    });

    test('returns at most two gaps', () {
      final gaps = selectThesisUnbackedGaps(_thesis(), limit: 2);

      expect(gaps.length, 2);
      expect(gaps.first.fieldKey, ThesisEvidenceFields.problem);
      expect(gaps.last.fieldKey, ThesisEvidenceFields.solution);
    });

    test('skips founder-claimed complete fields', () {
      final thesis = _thesis(
        problem: _filled,
        solution: _filled,
        targetAudience: _filled,
        businessModel: _filled,
        keyMetrics: _filled,
        advantages: _filled,
        risksGaps: _filled,
        fieldEvidence: {
          for (final key in thesisCoreFieldKeys)
            key: const ThesisFieldEvidence(
              kind: ThesisEvidenceKind.founderClaim,
            ),
        },
      );

      expect(selectThesisUnbackedGaps(thesis), isEmpty);
      expect(computeThesisReadiness(thesis).isComplete, isTrue);
    });
  });

  group('thesisReadinessAsPlanReadiness', () {
    test('keeps incomplete theses incomplete for the readiness ring', () {
      final readiness = computeThesisReadiness(_thesis(problem: _filled));
      final plan = thesisReadinessAsPlanReadiness(readiness);

      expect(plan.completedCount, 1);
      expect(plan.isComplete, isFalse);
      expect(plan.gapCount, 6);
    });
  });
}
