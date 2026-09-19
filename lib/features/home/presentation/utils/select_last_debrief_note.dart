import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';

/// Newest customer-discovery note, or null when Home has no debrief yet.
AudioNote? selectLastDebriefNote(List<AudioNote> notes) {
  AudioNote? latest;
  for (final note in notes) {
    if (note.templateId != RecordingTemplateIds.customerDiscovery) {
      continue;
    }
    if (latest == null || note.createdAt.isAfter(latest.createdAt)) {
      latest = note;
    }
  }
  return latest;
}
