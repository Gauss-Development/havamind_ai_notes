import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_field_evidence.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';
import 'package:sample/features/thesis/domain/utils/thesis_apply_ready.dart';

AudioNote _note({
  AudioNoteStatus status = AudioNoteStatus.completed,
  DateTime? updatedAt,
}) {
  final at = updatedAt ?? DateTime.utc(2026, 3, 1, 12);
  return AudioNote(
    id: 'note-1',
    userId: 'user-1',
    title: 'Debrief',
    audioPath: null,
    durationSeconds: 90,
    status: status,
    createdAt: at,
    updatedAt: at,
  );
}

Thesis _thesis({
  DateTime? updatedAt,
  Map<String, ThesisFieldEvidence> fieldEvidence = const {},
}) {
  final at = updatedAt ?? DateTime.utc(2026, 2, 1);
  return Thesis(
    id: 'thesis-1',
    userId: 'user-1',
    createdAt: at,
    updatedAt: at,
    fieldEvidence: fieldEvidence,
  );
}

ThesisVersion _version(DateTime createdAt) {
  return ThesisVersion(
    id: 'v1',
    thesisId: 'thesis-1',
    userId: 'user-1',
    roundNumber: 1,
    thesisSnapshot: const {'problem': 'Pain'},
    transcription: 'hello',
    createdAt: createdAt,
  );
}

void main() {
  test('completed note is ready when evidence stamps this note', () {
    final thesis = _thesis(
      fieldEvidence: {
        ThesisEvidenceFields.problem: const ThesisFieldEvidence(
          kind: ThesisEvidenceKind.customerSignal,
          noteId: 'note-1',
        ),
      },
    );

    expect(
      isThesisApplyReadyForNote(
        thesis: thesis,
        recentVersions: const [],
        note: _note(),
      ),
      isTrue,
    );
  });

  test('completed note is ready when a version lands after the note', () {
    final completedAt = DateTime.utc(2026, 3, 1, 12);
    expect(
      isThesisApplyReadyForNote(
        thesis: _thesis(),
        recentVersions: [_version(completedAt.add(const Duration(seconds: 8)))],
        note: _note(updatedAt: completedAt),
      ),
      isTrue,
    );
  });

  test('processing note is never ready', () {
    expect(
      isThesisApplyReadyForNote(
        thesis: _thesis(
          fieldEvidence: {
            ThesisEvidenceFields.problem: const ThesisFieldEvidence(
              kind: ThesisEvidenceKind.unbacked,
              noteId: 'note-1',
            ),
          },
        ),
        recentVersions: const [],
        note: _note(status: AudioNoteStatus.processingAnalysis),
      ),
      isFalse,
    );
  });

  test('completed note is not ready before apply writes', () {
    final completedAt = DateTime.utc(2026, 3, 1, 12);
    expect(
      isThesisApplyReadyForNote(
        thesis: _thesis(
          updatedAt: completedAt.subtract(const Duration(days: 1)),
        ),
        recentVersions: const [],
        note: _note(updatedAt: completedAt),
      ),
      isFalse,
    );
  });
}
