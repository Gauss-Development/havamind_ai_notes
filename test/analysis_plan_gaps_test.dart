import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/audio_notes/domain/utils/analysis_plan_gaps.dart';

StartupAnalysis _analysis({
  String? problem,
  String? solution,
  String? targetAudience,
  String? businessModel,
  String? keyMetrics,
  String? advantages,
  String? risksGaps,
}) {
  return StartupAnalysis(
    id: 'analysis-1',
    audioNoteId: 'note-1',
    userId: 'user-1',
    createdAt: DateTime(2024, 1, 1),
    problem: problem,
    solution: solution,
    targetAudience: targetAudience,
    businessModel: businessModel,
    keyMetrics: keyMetrics,
    advantages: advantages,
    risksGaps: risksGaps,
  );
}

void main() {
  group('isPlanFieldIncomplete', () {
    test('returns true for null, empty, and placeholder values', () {
      expect(isPlanFieldIncomplete(null), isTrue);
      expect(isPlanFieldIncomplete(''), isTrue);
      expect(isPlanFieldIncomplete('   '), isTrue);
      expect(isPlanFieldIncomplete('not specified'), isTrue);
      expect(isPlanFieldIncomplete('Not Specified'), isTrue);
      expect(isPlanFieldIncomplete('не указано'), isTrue);
      expect(isPlanFieldIncomplete('n/a'), isTrue);
    });

    test('returns true for very short text', () {
      expect(isPlanFieldIncomplete('Too short'), isTrue);
    });

    test('returns false for substantive content', () {
      expect(
        isPlanFieldIncomplete(
          'Founders struggle to capture ideas during walks and commutes.',
        ),
        isFalse,
      );
    });
  });

  group('findAnalysisPlanGaps', () {
    test('returns gaps for incomplete core fields only', () {
      final analysis = _analysis(
        problem: 'not specified',
        solution: 'A mobile app that turns voice memos into structured plans.',
        targetAudience: 'Early-stage founders',
        businessModel: null,
        keyMetrics: 'n/a',
        advantages: 'Fast capture with AI analysis on every note.',
        risksGaps: 'Needs stronger go-to-market detail.',
      );

      final gaps = findAnalysisPlanGaps(analysis);

      expect(gaps.map((g) => g.field).toList(), [
        StartupAnalysisEditableField.problem,
        StartupAnalysisEditableField.businessModel,
        StartupAnalysisEditableField.keyMetrics,
      ]);
    });

    test('returns empty list when all core fields are complete', () {
      final analysis = _analysis(
        problem: 'Founders lose ideas because capture is too slow.',
        solution: 'Voice-first notes with instant AI structuring.',
        targetAudience: 'Solo founders and small startup teams.',
        businessModel: 'Subscription with free tier and paid Pro plan.',
        keyMetrics: 'Weekly active recorders and plan completion rate.',
        advantages: 'Founder-specific prompts and venture intelligence.',
        risksGaps: 'Competition from generic note apps.',
      );

      expect(findAnalysisPlanGaps(analysis), isEmpty);
    });
  });

  group('computePlanReadiness', () {
    test('reports 100% when all seven core fields are complete', () {
      final analysis = _analysis(
        problem: 'Founders lose ideas because capture is too slow.',
        solution: 'Voice-first notes with instant AI structuring.',
        targetAudience: 'Solo founders and small startup teams.',
        businessModel: 'Subscription with free tier and paid Pro plan.',
        keyMetrics: 'Weekly active recorders and plan completion rate.',
        advantages: 'Founder-specific prompts and venture intelligence.',
        risksGaps: 'Competition from generic note apps.',
      );

      final readiness = computePlanReadiness(analysis);

      expect(readiness.percent, 100);
      expect(readiness.completedCount, kCorePlanFieldCount);
      expect(readiness.totalCount, kCorePlanFieldCount);
      expect(readiness.isComplete, isTrue);
    });

    test('reports partial readiness from gap count', () {
      final analysis = _analysis(
        problem: 'not specified',
        solution: 'Voice-first notes with instant AI structuring.',
        targetAudience: 'Solo founders and small startup teams.',
        businessModel: 'Subscription with free tier and paid Pro plan.',
        keyMetrics: 'Weekly active recorders and plan completion rate.',
        advantages: 'Founder-specific prompts and venture intelligence.',
        risksGaps: 'Competition from generic note apps.',
      );

      final readiness = computePlanReadiness(analysis);

      expect(readiness.percent, 86);
      expect(readiness.completedCount, 6);
      expect(readiness.gapCount, 1);
      expect(readiness.isComplete, isFalse);
    });
  });
}
