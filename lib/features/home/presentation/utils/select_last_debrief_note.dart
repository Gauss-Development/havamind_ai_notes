import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';

/// Newest founder-pitch note on Home. Customer discovery stays in the archive.
AudioNote? selectLastDebriefNote(List<AudioNote> notes) {
  AudioNote? latest;
  for (final note in notes) {
    if (note.templateId != RecordingTemplateIds.founderPitch) {
      continue;
    }
    if (latest == null || note.createdAt.isAfter(latest.createdAt)) {
      latest = note;
    }
  }
  return latest;
}
