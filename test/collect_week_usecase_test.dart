import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/repositories/thesis_repository.dart';
import 'package:sample/features/thesis/domain/usecases/collect_week_usecase.dart';

class _MockThesisRepository extends Mock implements ThesisRepository {}

class _MockAudioNotesRepository extends Mock implements AudioNotesRepository {}

AudioNote _note({
  required String id,
  required DateTime createdAt,
  String templateId = RecordingTemplateIds.customerDiscovery,
}) {
  return AudioNote(
    id: id,
    userId: 'user-1',
    title: id,
    audioPath: null,
    durationSeconds: 90,
    status: AudioNoteStatus.completed,
    createdAt: createdAt,
    updatedAt: createdAt,
    templateId: templateId,
  );
}

void main() {
  final now = DateTime.utc(2026, 9, 16, 16);
  final thesis = Thesis(
    id: 'thesis-1',
    userId: 'user-1',
    title: 'Havamind',
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 16),
  );

  late _MockThesisRepository thesisRepo;
  late _MockAudioNotesRepository notesRepo;
  late CollectWeekUseCase useCase;

  setUp(() {
    thesisRepo = _MockThesisRepository();
    notesRepo = _MockAudioNotesRepository();
    useCase = CollectWeekUseCase(
      thesisRepository: thesisRepo,
      audioNotesRepository: notesRepo,
      clock: () => now,
    );
  });

  test('returns thesis plus notes created in the last 7 days', () async {
    final inWeek = _note(id: 'debrief', createdAt: DateTime.utc(2026, 9, 14));
    final pitch = _note(
      id: 'pitch',
      createdAt: DateTime.utc(2026, 9, 15),
      templateId: RecordingTemplateIds.founderPitch,
    );
    final old = _note(id: 'old', createdAt: DateTime.utc(2026, 9, 1));
    when(() => thesisRepo.getCurrentThesis())
        .thenAnswer((_) async => Right(thesis));
    when(() => notesRepo.listNotes(limit: 100))
        .thenAnswer((_) async => Right([inWeek, pitch, old]));

    final result = await useCase(const NoParams());

    final export = result.getOrElse(() => throw StateError('expected right'));
    expect(export.thesis.id, 'thesis-1');
    expect(export.weekNotes.map((n) => n.id), ['pitch', 'debrief']);
    expect(export.weekDebriefs.map((n) => n.id), ['debrief']);
    expect(export.hasDebriefs, isTrue);
  });

  test(
    'hasDebriefs is false when the week has no customer-discovery notes',
    () async {
      when(() => thesisRepo.getCurrentThesis())
          .thenAnswer((_) async => Right(thesis));
      when(() => notesRepo.listNotes(limit: 100)).thenAnswer(
        (_) async => Right([
          _note(
            id: 'pitch',
            createdAt: DateTime.utc(2026, 9, 15),
            templateId: RecordingTemplateIds.founderPitch,
          ),
        ]),
      );

      final result = await useCase(const NoParams());

      final export = result.getOrElse(() => throw StateError('expected right'));
      expect(export.weekNotes, hasLength(1));
      expect(export.hasDebriefs, isFalse);
    },
  );

  test('returns NotFoundFailure when the account has no thesis', () async {
    when(() => thesisRepo.getCurrentThesis())
        .thenAnswer((_) async => const Right(null));

    final result = await useCase(const NoParams());

    expect(result, const Left(NotFoundFailure('No thesis')));
    verifyNever(() => notesRepo.listNotes(limit: any(named: 'limit')));
  });

  test('forwards a thesis read failure', () async {
    const failure = ServerFailure('down');
    when(() => thesisRepo.getCurrentThesis())
        .thenAnswer((_) async => const Left(failure));

    final result = await useCase(const NoParams());

    expect(result, const Left(failure));
  });
}
