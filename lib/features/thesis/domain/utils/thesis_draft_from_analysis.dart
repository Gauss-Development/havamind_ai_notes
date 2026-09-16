import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_field_evidence.dart';

/// Copies the seven plan fields plus title/summary into a thesis draft.
/// Populated fields are marked [ThesisEvidenceKind.founderClaim].
ThesisDraft thesisDraftFromAnalysis(StartupAnalysis analysis) {
  return ThesisDraft(
    title: analysis.startupTitle,
    shortSummary: analysis.shortSummary,
    problem: analysis.problem,
    solution: analysis.solution,
    targetAudience: analysis.targetAudience,
    businessModel: analysis.businessModel,
    keyMetrics: analysis.keyMetrics,
    advantages: analysis.advantages,
    risksGaps: analysis.risksGaps,
    followUpQuestions: analysis.followUpQuestions,
    fieldEvidence: founderClaimEvidenceFromAnalysis(analysis),
  );
}

Map<String, ThesisFieldEvidence> founderClaimEvidenceFromAnalysis(
  StartupAnalysis analysis,
) {
  final evidence = <String, ThesisFieldEvidence>{};

  void claim(String key, String? value) {
    if (value == null || value.trim().isEmpty) return;
    evidence[key] = ThesisFieldEvidence(
      kind: ThesisEvidenceKind.founderClaim,
      noteId: analysis.audioNoteId,
    );
  }

  claim(ThesisEvidenceFields.title, analysis.startupTitle);
  claim(ThesisEvidenceFields.shortSummary, analysis.shortSummary);
  claim(ThesisEvidenceFields.problem, analysis.problem);
  claim(ThesisEvidenceFields.solution, analysis.solution);
  claim(ThesisEvidenceFields.targetAudience, analysis.targetAudience);
  claim(ThesisEvidenceFields.businessModel, analysis.businessModel);
  claim(ThesisEvidenceFields.keyMetrics, analysis.keyMetrics);
  claim(ThesisEvidenceFields.advantages, analysis.advantages);
  claim(ThesisEvidenceFields.risksGaps, analysis.risksGaps);

  return evidence;
}
