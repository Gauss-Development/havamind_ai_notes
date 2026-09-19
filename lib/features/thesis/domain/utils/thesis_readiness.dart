import 'package:equatable/equatable.dart';

import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/audio_notes/domain/utils/analysis_plan_gaps.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_field_evidence.dart';

/// Core thesis stakes shown on Home (same seven fields as plan readiness).
const thesisCoreFieldKeys = [
  ThesisEvidenceFields.problem,
  ThesisEvidenceFields.solution,
  ThesisEvidenceFields.targetAudience,
  ThesisEvidenceFields.businessModel,
  ThesisEvidenceFields.keyMetrics,
  ThesisEvidenceFields.advantages,
  ThesisEvidenceFields.risksGaps,
];

/// A thesis field that is still an unbacked stake or empty.
class ThesisUnbackedGap extends Equatable {
  const ThesisUnbackedGap({required this.fieldKey});

  final String fieldKey;

  @override
  List<Object?> get props => [fieldKey];
}

/// Completeness of the seven core thesis fields.
class ThesisReadiness extends Equatable {
  const ThesisReadiness({
    required this.completedCount,
    required this.totalCount,
    required this.gaps,
  });

  final int completedCount;
  final int totalCount;
  final List<ThesisUnbackedGap> gaps;

  int get gapCount => gaps.length;

  int get percent {
    if (totalCount <= 0) return 0;
    return ((completedCount / totalCount) * 100).round().clamp(0, 100);
  }

  double get ratio => totalCount <= 0 ? 0 : completedCount / totalCount;

  bool get isComplete => gapCount == 0;

  /// No title and no filled core fields — first-run cold pitch, not debrief.
  bool isBlankThesis(Thesis thesis) {
    final title = thesis.title?.trim() ?? '';
    return title.isEmpty && completedCount == 0;
  }

  @override
  List<Object?> get props => [completedCount, totalCount, gaps];
}

String? thesisCoreFieldValue(Thesis thesis, String fieldKey) {
  switch (fieldKey) {
    case ThesisEvidenceFields.problem:
      return thesis.problem;
    case ThesisEvidenceFields.solution:
      return thesis.solution;
    case ThesisEvidenceFields.targetAudience:
      return thesis.targetAudience;
    case ThesisEvidenceFields.businessModel:
      return thesis.businessModel;
    case ThesisEvidenceFields.keyMetrics:
      return thesis.keyMetrics;
    case ThesisEvidenceFields.advantages:
      return thesis.advantages;
    case ThesisEvidenceFields.risksGaps:
      return thesis.risksGaps;
    default:
      return null;
  }
}

/// Text-completeness readiness for the seven core fields.
ThesisReadiness computeThesisReadiness(Thesis thesis) {
  final incomplete = <ThesisUnbackedGap>[];
  for (final key in thesisCoreFieldKeys) {
    if (isPlanFieldIncomplete(thesisCoreFieldValue(thesis, key))) {
      incomplete.add(ThesisUnbackedGap(fieldKey: key));
    }
  }
  return ThesisReadiness(
    completedCount: thesisCoreFieldKeys.length - incomplete.length,
    totalCount: thesisCoreFieldKeys.length,
    gaps: incomplete,
  );
}

bool _isUnbackedStake(Thesis thesis, String fieldKey) {
  final evidence = thesis.fieldEvidence[fieldKey];
  if (evidence?.kind == ThesisEvidenceKind.unbacked) return true;
  if (evidence == null) {
    return isPlanFieldIncomplete(thesisCoreFieldValue(thesis, fieldKey));
  }
  return false;
}

/// Up to [limit] unbacked stakes for the Home card (evidence first, then empty).
List<ThesisUnbackedGap> selectThesisUnbackedGaps(
  Thesis thesis, {
  int limit = 2,
}) {
  if (limit <= 0) return const [];

  final marked = <ThesisUnbackedGap>[];
  final empty = <ThesisUnbackedGap>[];

  for (final key in thesisCoreFieldKeys) {
    if (!_isUnbackedStake(thesis, key)) continue;
    final gap = ThesisUnbackedGap(fieldKey: key);
    if (thesis.fieldEvidence[key]?.kind == ThesisEvidenceKind.unbacked) {
      marked.add(gap);
    } else {
      empty.add(gap);
    }
  }

  return [...marked, ...empty].take(limit).toList(growable: false);
}

/// Maps a thesis field key onto [PlanReadiness] so Home can reuse the ring.
PlanReadiness thesisReadinessAsPlanReadiness(ThesisReadiness readiness) {
  return PlanReadiness(
    completedCount: readiness.completedCount,
    totalCount: readiness.totalCount,
    gaps: [
      for (final gap in readiness.gaps)
        AnalysisPlanGap(field: _editableFieldForThesisKey(gap.fieldKey)),
    ],
  );
}

StartupAnalysisEditableField _editableFieldForThesisKey(String fieldKey) {
  switch (fieldKey) {
    case ThesisEvidenceFields.problem:
      return StartupAnalysisEditableField.problem;
    case ThesisEvidenceFields.solution:
      return StartupAnalysisEditableField.solution;
    case ThesisEvidenceFields.targetAudience:
      return StartupAnalysisEditableField.targetAudience;
    case ThesisEvidenceFields.businessModel:
      return StartupAnalysisEditableField.businessModel;
    case ThesisEvidenceFields.keyMetrics:
      return StartupAnalysisEditableField.keyMetrics;
    case ThesisEvidenceFields.advantages:
      return StartupAnalysisEditableField.advantages;
    case ThesisEvidenceFields.risksGaps:
      return StartupAnalysisEditableField.risksGaps;
    default:
      return StartupAnalysisEditableField.problem;
  }
}
