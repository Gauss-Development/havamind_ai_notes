import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';
import 'package:sample/features/audio_notes/domain/usecases/delete_audio_note_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/delete_local_audio_file_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/get_audio_note_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/get_note_analysis_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/get_note_transcript_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/request_processing_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/update_analysis_field_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/update_note_title_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/watch_audio_note_usecase.dart';
import 'package:sample/features/audio_notes/presentation/bloc/note_detail_bloc.dart';

class _MockRepo extends Mock implements AudioNotesRepository {}

void main() {
  late _MockRepo repo;
  late NoteDetailBloc bloc;

  final note = AudioNote(
    id: 'n1',
    userId: 'u1',
    title: 't',
    audioPath: 'u1/n1/f.m4a',
    durationSeconds: 5,
    status: AudioNoteStatus.uploaded,
    createdAt: DateTime.utc(2025),
    updatedAt: DateTime.utc(2025),
  );

  setUp(() {
    repo = _MockRepo();
    when(() => repo.getNote('n1')).thenAnswer((_) async => Right(note));
    when(
      () => repo.watchNote('n1'),
    ).thenAnswer((_) => const Stream<AudioNote>.empty());
    bloc = NoteDetailBloc(
      getAudioNote: GetAudioNoteUseCase(repo),
      deleteAudioNote: DeleteAudioNoteUseCase(repo),
      deleteLocalAudioFile: DeleteLocalAudioFileUseCase(repo),
      getTranscript: GetNoteTranscriptUseCase(repo),
      getAnalysis: GetNoteAnalysisUseCase(repo),
      updateAnalysisField: UpdateAnalysisFieldUseCase(repo),
      updateNoteTitle: UpdateNoteTitleUseCase(repo),
      requestProcessing: RequestProcessingUseCase(repo),
      watchNote: WatchAudioNoteUseCase(repo),
      noteId: 'n1',
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  test('loads note on create', () async {
    final state = await bloc.stream.firstWhere(
      (s) => s.maybeWhen(
        loaded: (note, transcript, analysis, localAudioExists) => true,
        orElse: () => false,
      ),
    );
    expect(
      state,
      NoteDetailState.loaded(
        note: note,
        transcript: null,
        analysis: null,
        localAudioExists: false,
      ),
    );
  });

  test('delete success emits deleted', () async {
    await bloc.stream.firstWhere(
      (s) => s.maybeWhen(
        loaded: (note, transcript, analysis, localAudioExists) => true,
        orElse: () => false,
      ),
    );
    when(
      () => repo.deleteNote('n1'),
    ).thenAnswer((_) async => const Right(unit));
    bloc.add(const NoteDetailEvent.deleteRequested());
    await expectLater(
      bloc.stream,
      emitsInOrder(<NoteDetailState>[
        const NoteDetailState.loading(),
        const NoteDetailState.deleted(),
      ]),
    );
  });
}
