import 'package:equatable/equatable.dart';

class AudioNoteTranscript extends Equatable {
  const AudioNoteTranscript({
    required this.id,
    required this.audioNoteId,
    required this.userId,
    required this.transcriptText,
    this.language,
    required this.createdAt,
  });

  final String id;
  final String audioNoteId;
  final String userId;
  final String transcriptText;
  final String? language;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    audioNoteId,
    userId,
    transcriptText,
    language,
    createdAt,
  ];
}
