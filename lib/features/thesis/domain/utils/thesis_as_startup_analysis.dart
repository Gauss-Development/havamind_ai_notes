import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';

/// Maps the living thesis onto the analysis shape [PlanExportFormatter] expects.
///
/// Scores stay null — the weekly letter does not resurrect 0–100 wow.
StartupAnalysis thesisAsStartupAnalysis(Thesis thesis) {
  return StartupAnalysis(
    id: thesis.id,
    audioNoteId: thesis.id,
    userId: thesis.userId,
    startupTitle: thesis.title,
    shortSummary: thesis.shortSummary,
    problem: thesis.problem,
    solution: thesis.solution,
    targetAudience: thesis.targetAudience,
    businessModel: thesis.businessModel,
    keyMetrics: thesis.keyMetrics,
    advantages: thesis.advantages,
    risksGaps: thesis.risksGaps,
    followUpQuestions: thesis.followUpQuestions,
    createdAt: thesis.updatedAt,
  );
}
