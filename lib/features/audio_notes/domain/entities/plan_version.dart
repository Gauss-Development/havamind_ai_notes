import 'package:equatable/equatable.dart';

class PlanVersion extends Equatable {
  const PlanVersion({
    required this.id,
    required this.planId,
    required this.audioNoteId,
    required this.roundNumber,
    required this.planSnapshot,
    this.transcription,
    this.diffSummary,
    this.followUpQuestions,
    required this.createdAt,
  });

  final String id;
  final String planId;
  final String audioNoteId;
  final int roundNumber;
  final Map<String, dynamic> planSnapshot;
  final String? transcription;
  final String? diffSummary;
  final List<String>? followUpQuestions;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    planId,
    audioNoteId,
    roundNumber,
    planSnapshot,
    transcription,
    diffSummary,
    followUpQuestions,
    createdAt,
  ];
}
