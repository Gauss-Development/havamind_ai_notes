import 'package:equatable/equatable.dart';

import '../entities/startup_analysis.dart';

/// A section of the business plan that is missing or too weak after analysis.
class AnalysisPlanGap extends Equatable {
  const AnalysisPlanGap({required this.field});

  final StartupAnalysisEditableField field;

  @override
  List<Object?> get props => [field];
}

const _incompleteSentinels = {
  'not specified',
  'n/a',
  'na',
  'none',
  'unknown',
  'tbd',
  'не указано',
  'не указан',
  'не указана',
  'нет данных',
};

/// Returns true when [value] is null, empty, a placeholder, or too short.
bool isPlanFieldIncomplete(String? value, {int minLength = 12}) {
  if (value == null) return true;

  final trimmed = value.trim();
  if (trimmed.isEmpty) return true;
  if (trimmed.length < minLength) return true;

  final normalized = trimmed.toLowerCase();
  if (_incompleteSentinels.contains(normalized)) return true;

  return false;
}

/// Detects which core plan fields need a follow-up voice recording.
List<AnalysisPlanGap> findAnalysisPlanGaps(StartupAnalysis analysis) {
  final gaps = <AnalysisPlanGap>[];

  void check(StartupAnalysisEditableField field, String? value) {
    if (isPlanFieldIncomplete(value)) {
      gaps.add(AnalysisPlanGap(field: field));
    }
  }

  check(StartupAnalysisEditableField.problem, analysis.problem);
  check(StartupAnalysisEditableField.solution, analysis.solution);
  check(StartupAnalysisEditableField.targetAudience, analysis.targetAudience);
  check(StartupAnalysisEditableField.businessModel, analysis.businessModel);
  check(StartupAnalysisEditableField.keyMetrics, analysis.keyMetrics);
  check(StartupAnalysisEditableField.advantages, analysis.advantages);
  check(StartupAnalysisEditableField.risksGaps, analysis.risksGaps);

  return gaps;
}

/// Number of core plan fields tracked for readiness scoring.
const kCorePlanFieldCount = 7;

/// Aggregated readiness for the seven core business-plan sections.
class PlanReadiness extends Equatable {
  const PlanReadiness({
    required this.completedCount,
    required this.totalCount,
    required this.gaps,
  });

  final int completedCount;
  final int totalCount;
  final List<AnalysisPlanGap> gaps;

  int get gapCount => gaps.length;

  int get percent {
    if (totalCount <= 0) return 0;
    return ((completedCount / totalCount) * 100).round().clamp(0, 100);
  }

  double get ratio => totalCount <= 0 ? 0 : completedCount / totalCount;

  bool get isComplete => gapCount == 0;

  @override
  List<Object?> get props => [completedCount, totalCount, gaps];
}

PlanReadiness computePlanReadiness(StartupAnalysis analysis) {
  final gaps = findAnalysisPlanGaps(analysis);
  return PlanReadiness(
    completedCount: kCorePlanFieldCount - gaps.length,
    totalCount: kCorePlanFieldCount,
    gaps: gaps,
  );
}

String? planFieldValue(
  StartupAnalysis analysis,
  StartupAnalysisEditableField field,
) {
  return switch (field) {
    StartupAnalysisEditableField.problem => analysis.problem,
    StartupAnalysisEditableField.solution => analysis.solution,
    StartupAnalysisEditableField.targetAudience => analysis.targetAudience,
    StartupAnalysisEditableField.businessModel => analysis.businessModel,
    StartupAnalysisEditableField.keyMetrics => analysis.keyMetrics,
    StartupAnalysisEditableField.advantages => analysis.advantages,
    StartupAnalysisEditableField.risksGaps => analysis.risksGaps,
    StartupAnalysisEditableField.shortSummary => analysis.shortSummary,
    StartupAnalysisEditableField.startupTitle => analysis.startupTitle,
  };
}
