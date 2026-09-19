import 'package:sample/features/audio_notes/domain/utils/analysis_plan_gaps.dart';
import 'package:sample/features/thesis/domain/entities/thesis_seed_candidate.dart';

/// Picks the completed analysis with the highest [PlanReadiness.percent].
/// Ties go to the most recently created completed note.
ThesisSeedCandidate? selectBestThesisSeedCandidate(
  List<ThesisSeedCandidate> candidates,
) {
  if (candidates.isEmpty) return null;

  return candidates.reduce((best, next) {
    final bestPercent = computePlanReadiness(best.analysis).percent;
    final nextPercent = computePlanReadiness(next.analysis).percent;
    if (nextPercent > bestPercent) return next;
    if (nextPercent < bestPercent) return best;
    return next.noteCreatedAt.isAfter(best.noteCreatedAt) ? next : best;
  });
}
