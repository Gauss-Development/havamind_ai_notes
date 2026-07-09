import 'package:equatable/equatable.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';

class AudioNote extends Equatable {
  const AudioNote({
    required this.id,
    required this.userId,
    required this.title,
    required this.audioPath,
    required this.durationSeconds,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.templateId = RecordingTemplateIds.founderPitch,
    this.lastProcessingError,
  });

  final String id;
  final String userId;
  final String title;

  /// Path within bucket `audio-notes` (user_id/note_id/file.m4a).
  ///
  /// Null once the note is completed: the audio is ephemeral staging data and
  /// gets removed after processing, leaving the transcript/analysis as the
  /// durable artifacts.
  final String? audioPath;
  final int durationSeconds;
  final AudioNoteStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Recording/analysis template (`founder_pitch`, `customer_discovery`, …).
  final String templateId;

  /// Set when [status] is [AudioNoteStatus.failed] (Edge Function or client).
  final String? lastProcessingError;

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    audioPath,
    durationSeconds,
    status,
    createdAt,
    updatedAt,
    templateId,
    lastProcessingError,
  ];
}
