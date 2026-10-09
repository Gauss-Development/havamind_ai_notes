import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/home/presentation/utils/select_last_debrief_note.dart';

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
  test('returns null when there is no founder pitch', () {
    final notes = [
      _note(
        id: 'discovery',
        createdAt: DateTime.utc(2026, 3, 1),
        templateId: RecordingTemplateIds.customerDiscovery,
      ),
    ];

    expect(selectLastDebriefNote(notes), isNull);
  });

  test('returns the newest founder pitch and skips customer discovery', () {
    final older = _note(id: 'old', createdAt: DateTime.utc(2026, 2, 1));
    final newer = _note(id: 'new', createdAt: DateTime.utc(2026, 4, 1));
    final discovery = _note(
      id: 'discovery',
      createdAt: DateTime.utc(2026, 5, 1),
      templateId: RecordingTemplateIds.customerDiscovery,
    );

    final last = selectLastDebriefNote([older, discovery, newer]);

    expect(last?.id, 'new');
  });
}
