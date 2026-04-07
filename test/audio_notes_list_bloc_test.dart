import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';
import 'package:sample/features/audio_notes/domain/usecases/list_audio_notes_usecase.dart';
import 'package:sample/features/audio_notes/presentation/bloc/audio_notes_list_bloc.dart';

class _MockRepo extends Mock implements AudioNotesRepository {}

void main() {
  late _MockRepo repo;
  late AudioNotesListBloc bloc;

  final note = AudioNote(
    id: 'n1',
    userId: 'u1',
    title: 't',
    audioPath: 'p',
    durationSeconds: 1,
    status: AudioNoteStatus.uploaded,
    createdAt: DateTime.utc(2025),
    updatedAt: DateTime.utc(2025),
  );

  setUp(() {
    repo = _MockRepo();
    bloc = AudioNotesListBloc(listAudioNotes: ListAudioNotesUseCase(repo));
  });

  tearDown(() async {
    await bloc.close();
  });

  test('started loads notes', () async {
    when(
      () => repo.listNotes(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => Right([note]));
    bloc.add(const AudioNotesListEvent.started());
    await expectLater(
      bloc.stream,
      emitsInOrder(<AudioNotesListState>[
        const AudioNotesListState.loading(),
        AudioNotesListState.loaded([note], hasReachedEnd: true),
      ]),
    );
  });

  test('started failure emits failure', () async {
    when(
      () => repo.listNotes(
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer(
      (_) async =>
          const Left<Failure, List<AudioNote>>(UnexpectedFailure('x')),
    );
    bloc.add(const AudioNotesListEvent.started());
    await expectLater(
      bloc.stream,
      emitsInOrder(<AudioNotesListState>[
        const AudioNotesListState.loading(),
        const AudioNotesListState.failure('x'),
      ]),
    );
  });
}
