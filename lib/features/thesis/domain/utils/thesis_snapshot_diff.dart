import 'package:sample/features/audio_notes/domain/utils/plan_snapshot_diff.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';

/// Remaps a thesis / thesis_version snapshot onto [planSnapshotFieldKeys].
Map<String, dynamic> thesisSnapshotAsPlanSnapshot(
  Map<String, dynamic> snapshot,
) {
  return {
    'startup_title': snapshot['startup_title'] ?? snapshot['title'],
    'short_summary': snapshot['short_summary'],
    'problem': snapshot['problem'],
    'solution': snapshot['solution'],
    'target_audience': snapshot['target_audience'],
    'business_model': snapshot['business_model'],
    'key_metrics': snapshot['key_metrics'],
    'advantages': snapshot['advantages'],
    'risks_gaps': snapshot['risks_gaps'],
    'market_potential_score': snapshot['market_potential_score'],
    'technical_complexity_score': snapshot['technical_complexity_score'],
  };
}

/// Live thesis row as a snapshot when `thesis_versions` has not landed yet.
Map<String, dynamic> thesisAsSnapshot(Thesis thesis) {
  return {
    'title': thesis.title,
    'short_summary': thesis.shortSummary,
    'problem': thesis.problem,
    'solution': thesis.solution,
    'target_audience': thesis.targetAudience,
    'business_model': thesis.businessModel,
    'key_metrics': thesis.keyMetrics,
    'advantages': thesis.advantages,
    'risks_gaps': thesis.risksGaps,
  };
}

/// Field-level diff. Reuses [diffPlanSnapshots]; an empty previous snapshot
/// is treated as all-new populated fields (first apply after a blank thesis).
PlanSnapshotDiff diffThesisSnapshots({
  Map<String, dynamic>? previous,
  required Map<String, dynamic> current,
}) {
  final currentPlan = thesisSnapshotAsPlanSnapshot(current);
  if (previous == null || previous.isEmpty) {
    return diffPlanSnapshots(
      previous: {for (final key in planSnapshotFieldKeys) key: ''},
      current: currentPlan,
    );
  }
  return diffPlanSnapshots(
    previous: thesisSnapshotAsPlanSnapshot(previous),
    current: currentPlan,
  );
}
