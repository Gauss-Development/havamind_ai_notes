import 'package:equatable/equatable.dart';

/// Whether a frozen speech has already been heard.
enum HearingStatus {
  unheard,
  heard;

  static HearingStatus fromDb(String? raw) {
    return raw == 'heard' ? HearingStatus.heard : HearingStatus.unheard;
  }
}

/// A past speech of the concept. After [HearingStatus.heard] the snapshot
/// is read-only and carries the label of who heard it.
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
    this.hearingStatus = HearingStatus.unheard,
    this.heardByLabel,
    this.heardAt,
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

  final HearingStatus hearingStatus;

  /// Founder-confirmed label. Not a Havamind user id.
  final String? heardByLabel;
  final DateTime? heardAt;
  final DateTime createdAt;

  bool get wasHeard =>
      hearingStatus == HearingStatus.heard &&
      (heardByLabel?.trim().isNotEmpty ?? false);

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
    hearingStatus,
    heardByLabel,
    heardAt,
    createdAt,
  ];
}
