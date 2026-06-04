import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';

class AudioNoteMapper {
  static AudioNote fromRow(Map<String, dynamic> row) {
    return AudioNote(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      audioPath: row['audio_path'] as String,
      durationSeconds: (row['duration_seconds'] as num).toInt(),
      status: AudioNoteStatus.fromDb(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      templateId: RecordingTemplateIds.normalize(
        row['template_id'] as String?,
      ),
      lastProcessingError: row['last_processing_error'] as String?,
    );
  }
}
