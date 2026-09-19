import 'package:equatable/equatable.dart';

import 'package:sample/features/thesis/domain/entities/thesis_field_evidence.dart';

/// One living company thesis per account. Notes are events that may point
/// at this row via `audio_notes.thesis_id`.
class Thesis extends Equatable {
  const Thesis({
    required this.id,
    required this.userId,
    this.title,
    this.shortSummary,
    this.problem,
    this.solution,
    this.targetAudience,
    this.businessModel,
    this.keyMetrics,
    this.advantages,
    this.risksGaps,
    this.followUpQuestions,
    this.nextConversationScript,
    this.fieldEvidence = const {},
    this.debriefCount = 0,
    this.weekArtifactShareCount = 0,
    this.weekArtifactSharedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String? title;
  final String? shortSummary;
  final String? problem;
  final String? solution;
  final String? targetAudience;
  final String? businessModel;
  final String? keyMetrics;
  final String? advantages;
  final String? risksGaps;
  final List<String>? followUpQuestions;
  final String? nextConversationScript;
  final Map<String, ThesisFieldEvidence> fieldEvidence;

  /// customer_discovery applies. Cold pitch / seed stay at 0.
  final int debriefCount;

  /// Weekly letter handed to the OS share sheet (not copy / generate).
  final int weekArtifactShareCount;
  final DateTime? weekArtifactSharedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    shortSummary,
    problem,
    solution,
    targetAudience,
    businessModel,
    keyMetrics,
    advantages,
    risksGaps,
    followUpQuestions,
    nextConversationScript,
    fieldEvidence,
    debriefCount,
    weekArtifactShareCount,
    weekArtifactSharedAt,
    createdAt,
    updatedAt,
  ];
}

/// Client-side payload for inserting a thesis. Id, user, and timestamps
/// are assigned by the repository / database.
class ThesisDraft extends Equatable {
  const ThesisDraft({
    this.title,
    this.shortSummary,
    this.problem,
    this.solution,
    this.targetAudience,
    this.businessModel,
    this.keyMetrics,
    this.advantages,
    this.risksGaps,
    this.followUpQuestions,
    this.nextConversationScript,
    this.fieldEvidence = const {},
  });

  final String? title;
  final String? shortSummary;
  final String? problem;
  final String? solution;
  final String? targetAudience;
  final String? businessModel;
  final String? keyMetrics;
  final String? advantages;
  final String? risksGaps;
  final List<String>? followUpQuestions;
  final String? nextConversationScript;
  final Map<String, ThesisFieldEvidence> fieldEvidence;

  @override
  List<Object?> get props => [
    title,
    shortSummary,
    problem,
    solution,
    targetAudience,
    businessModel,
    keyMetrics,
    advantages,
    risksGaps,
    followUpQuestions,
    nextConversationScript,
    fieldEvidence,
  ];
}
