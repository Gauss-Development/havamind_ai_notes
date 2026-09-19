import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';

/// Apply-debrief stamps `field_evidence.note_id` after the note is completed.
bool thesisHasEvidenceForNote(Thesis thesis, String noteId) {
  return thesis.fieldEvidence.values.any(
    (evidence) => evidence.noteId == noteId,
  );
}

/// True when apply-debrief has landed for [note] (completed only).
///
/// `process-audio-note` marks `completed` *before* apply runs, so the client
/// must wait for evidence, a newer version, or a newer thesis `updated_at`.
bool isThesisApplyReadyForNote({
  required Thesis thesis,
  required List<ThesisVersion> recentVersions,
  required AudioNote note,
}) {
  if (note.status != AudioNoteStatus.completed) return false;
  if (thesisHasEvidenceForNote(thesis, note.id)) return true;

  final threshold = note.updatedAt.subtract(const Duration(seconds: 2));
  if (!thesis.updatedAt.isBefore(threshold)) return true;
  if (recentVersions.isEmpty) return false;
  return !recentVersions.first.createdAt.isBefore(threshold);
}
