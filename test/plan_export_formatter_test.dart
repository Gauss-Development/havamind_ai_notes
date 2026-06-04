import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/audio_notes/presentation/utils/plan_export_formatter.dart';

StartupAnalysis _analysis() {
  return StartupAnalysis(
    id: 'a1',
    audioNoteId: 'n1',
    userId: 'u1',
    startupTitle: 'Hava Mind',
    shortSummary: 'AI voice memos for founders.',
    problem: 'Founders lose ideas in unstructured voice notes.',
    solution: 'Structured startup plans from voice.',
    targetAudience: 'Early-stage founders',
    businessModel: 'Freemium SaaS',
    keyMetrics: 'Weekly active notes, plan readiness',
    advantages: 'Voice-first workflow',
    risksGaps: 'Needs stronger GTM',
    marketPotentialScore: 72,
    technicalComplexityScore: 48,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('PlanExportFormatter', () {
    test('onePager includes title, sections, and footer', () {
      final text = PlanExportFormatter.onePager(_analysis());

      expect(text, contains('# Hava Mind'));
      expect(text, contains('## Elevator pitch'));
      expect(text, contains('## Problem'));
      expect(text, contains('Generated with Hava Mind'));
      expect(text, contains('Market potential 72%'));
    });

    test('pitchBullets uses bullet lines for filled fields', () {
      final text = PlanExportFormatter.pitchBullets(_analysis());

      expect(text, contains('• Hava Mind'));
      expect(text, contains('• Problem: Founders lose ideas'));
      expect(text, contains('• Metrics: Weekly active notes'));
    });

    test('emailIntro composes intro from pitch and problem/solution', () {
      final text = PlanExportFormatter.emailIntro(_analysis());

      expect(text, contains('Hi — quick intro on Hava Mind:'));
      expect(text, contains('AI voice memos for founders.'));
      expect(text, contains("We're solving Founders lose ideas"));
      expect(text, contains('Happy to share more if useful.'));
    });
  });
}
