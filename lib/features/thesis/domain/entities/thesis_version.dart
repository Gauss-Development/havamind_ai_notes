import 'package:equatable/equatable.dart';

/// A historical snapshot of a thesis, matching the `plan_versions` contract
/// (snapshot, transcription, diff_summary, round_number) on the thesis axis.
class ThesisVersion extends Equatable {
  const ThesisVersion({
    required this.id,
    required this.thesisId,
    required this.userId,
    required this.roundNumber,
    required this.thesisSnapshot,
    required this.transcription,
    this.diffSummary,
    this.followUpQuestions,
    this.sourceNoteId,
    this.sourceTemplateId,
    required this.createdAt,
  });

  final String id;
  final String thesisId;
  final String userId;
  final int roundNumber;
  final Map<String, dynamic> thesisSnapshot;
  final String transcription;
  final String? diffSummary;
  final List<String>? followUpQuestions;

  /// Note that produced this version; used to count debrief returns.
  final String? sourceNoteId;
  final String? sourceTemplateId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    thesisId,
    userId,
    roundNumber,
    thesisSnapshot,
    transcription,
    diffSummary,
    followUpQuestions,
    sourceNoteId,
    sourceTemplateId,
    createdAt,
  ];
}
