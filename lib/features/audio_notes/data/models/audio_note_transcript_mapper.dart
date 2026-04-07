import 'package:sample/features/audio_notes/domain/entities/audio_note_transcript.dart';

class AudioNoteTranscriptMapper {
  static AudioNoteTranscript fromRow(Map<String, dynamic> row) {
    return AudioNoteTranscript(
      id: row['id'] as String,
      audioNoteId: row['audio_note_id'] as String,
      userId: row['user_id'] as String,
      transcriptText: row['transcript_text'] as String,
      language: row['language'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
