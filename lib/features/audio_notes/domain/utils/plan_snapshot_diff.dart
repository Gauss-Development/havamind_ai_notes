import 'package:equatable/equatable.dart';

/// Keys aligned with [PlanSnapshot] from refine-plan edge function.
const planSnapshotFieldKeys = [
  'startup_title',
  'short_summary',
  'problem',
  'solution',
  'target_audience',
  'business_model',
  'key_metrics',
  'advantages',
  'risks_gaps',
  'market_potential_score',
  'technical_complexity_score',
];

class PlanSnapshotFieldChange extends Equatable {
  const PlanSnapshotFieldChange({
    required this.fieldKey,
    this.before,
    required this.after,
  });

  final String fieldKey;
  final String? before;
  final String after;

  bool get isNew => before == null || before!.trim().isEmpty;

  @override
  List<Object?> get props => [fieldKey, before, after];
}

class PlanSnapshotDiff extends Equatable {
  const PlanSnapshotDiff({required this.changes});

  final List<PlanSnapshotFieldChange> changes;

  bool get isEmpty => changes.isEmpty;

  @override
  List<Object?> get props => [changes];
}

PlanSnapshotDiff diffPlanSnapshots({
  Map<String, dynamic>? previous,
  required Map<String, dynamic> current,
}) {
  if (previous == null || previous.isEmpty) {
    return const PlanSnapshotDiff(changes: []);
  }

  final changes = <PlanSnapshotFieldChange>[];

  for (final key in planSnapshotFieldKeys) {
    final beforeRaw = previous[key];
    final afterRaw = current[key];

    final before = _normalizeFieldValue(beforeRaw);
    final after = _normalizeFieldValue(afterRaw);

    if (before == after) continue;
    if (after == null) continue;

    changes.add(
      PlanSnapshotFieldChange(fieldKey: key, before: before, after: after),
    );
  }

  return PlanSnapshotDiff(changes: changes);
}

String? _normalizeFieldValue(Object? value) {
  if (value == null) return null;
  if (value is num) return '${value.toInt()}%';
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return text;
}
