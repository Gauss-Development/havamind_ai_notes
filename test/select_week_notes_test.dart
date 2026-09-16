import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/thesis/domain/utils/select_week_notes.dart';

AudioNote _note({
  required String id,
  required DateTime createdAt,
  String templateId = RecordingTemplateIds.founderPitch,
}) {
  return AudioNote(
    id: id,
    userId: 'user-1',
    title: id,
    audioPath: null,
    durationSeconds: 60,
    status: AudioNoteStatus.completed,
    createdAt: createdAt,
    updatedAt: createdAt,
    templateId: templateId,
  );
}

void main() {
  final now = DateTime.utc(2026, 9, 16, 16);

  group('selectNotesCreatedSince', () {
    test('keeps notes on or after the 7-day bound, newest first', () {
      final since = weekExportSince(now);
      final inside = _note(
        id: 'in',
        createdAt: now.subtract(const Duration(days: 2)),
      );
      final edge = _note(id: 'edge', createdAt: since);
      final older = _note(
        id: 'old',
        createdAt: since.subtract(const Duration(seconds: 1)),
      );
      final newest = _note(id: 'new', createdAt: now);

      final selected = selectNotesCreatedSince([
        inside,
        older,
        newest,
        edge,
      ], since);

      expect(selected.map((n) => n.id), ['new', 'in', 'edge']);
    });
  });

  group('selectWeekDebriefs', () {
    test('keeps only customer-discovery notes', () {
      final debrief = _note(
        id: 'd1',
        createdAt: now,
        templateId: RecordingTemplateIds.customerDiscovery,
      );
      final pitch = _note(id: 'p1', createdAt: now);
      final update = _note(
        id: 'u1',
        createdAt: now,
        templateId: RecordingTemplateIds.investorUpdate,
      );

      expect(selectWeekDebriefs([debrief, pitch, update]).map((n) => n.id), [
        'd1',
      ]);
    });
  });
}
