import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/usecases/get_audio_note_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/request_processing_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/watch_audio_note_usecase.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_field_evidence.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';
import 'package:sample/features/thesis/domain/usecases/get_thesis_usecase.dart';
import 'package:sample/features/thesis/domain/usecases/list_thesis_versions_usecase.dart';
import 'package:sample/features/thesis/presentation/cubit/thesis_result_cubit.dart';

class _MockWatchNote extends Mock implements WatchAudioNoteUseCase {}

class _MockGetNote extends Mock implements GetAudioNoteUseCase {}

class _MockGetThesis extends Mock implements GetThesisUseCase {}

class _MockListVersions extends Mock implements ListThesisVersionsUseCase {}

class _MockRequestProcessing extends Mock implements RequestProcessingUseCase {}

AudioNote _note({
  AudioNoteStatus status = AudioNoteStatus.processingAnalysis,
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
  String? nextConversationScript,
  Map<String, ThesisFieldEvidence> fieldEvidence = const {},
}) {
  final at = updatedAt ?? DateTime.utc(2026, 3, 1, 12, 0, 10);
  return Thesis(
    id: 'thesis-1',
    userId: 'user-1',
    title: 'Havamind',
    problem: 'Founders lose the thread after a real conversation.',
    nextConversationScript: nextConversationScript,
    fieldEvidence: fieldEvidence,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: at,
  );
}

ThesisVersion _version() {
  return ThesisVersion(
    id: 'v2',
    thesisId: 'thesis-1',
    userId: 'user-1',
    roundNumber: 2,
    thesisSnapshot: const {
      'title': 'Havamind',
      'problem': 'Founders lose the thread after a real conversation.',
    },
    transcription: 'we spoke to a clinic',
    diffSummary: 'Problem now cites the clinic call.',
    createdAt: DateTime.utc(2026, 3, 1, 12, 0, 12),
  );
}

void main() {
  late _MockWatchNote watchNote;
  late _MockGetNote getNote;
  late _MockGetThesis getThesis;
  late _MockListVersions listVersions;
  late _MockRequestProcessing requestProcessing;
  late StreamController<AudioNote?> notes;
  late ThesisResultCubit cubit;

  setUpAll(() {
    registerFallbackValue(const GetAudioNoteParams('note-1'));
    registerFallbackValue(const NoParams());
    registerFallbackValue(const ListThesisVersionsParams());
  });

  setUp(() {
    watchNote = _MockWatchNote();
    getNote = _MockGetNote();
    getThesis = _MockGetThesis();
    listVersions = _MockListVersions();
    requestProcessing = _MockRequestProcessing();
    notes = StreamController<AudioNote?>.broadcast();
    when(() => watchNote(any())).thenAnswer((_) => notes.stream);
    cubit = ThesisResultCubit(
      noteId: 'note-1',
      watchNote: watchNote,
      getAudioNote: getNote,
      getThesis: getThesis,
      listVersions: listVersions,
      requestProcessing: requestProcessing,
      applyPollInterval: Duration.zero,
      applyPollAttempts: 3,
    );
  });

  tearDown(() async {
    await cubit.close();
    await notes.close();
  });

  test('start emits processing while the note is in the pipeline', () async {
    when(() => getNote(any())).thenAnswer((_) async => Right(_note()));

    await cubit.start();

    expect(cubit.state, isA<ThesisResultProcessing>());
  });

  test('completed note with apply ready emits loaded', () async {
    final completed = _note(status: AudioNoteStatus.completed);
    final thesis = _thesis(
      fieldEvidence: {
        ThesisEvidenceFields.problem: const ThesisFieldEvidence(
          kind: ThesisEvidenceKind.customerSignal,
          noteId: 'note-1',
        ),
      },
      nextConversationScript:
          'Who: clinic ops\nHypothesis: they already pay\nWhat not to ask: do not pitch',
    );
    when(() => getNote(any())).thenAnswer((_) async => Right(completed));
    when(() => getThesis(any())).thenAnswer((_) async => Right(thesis));
    when(
      () => listVersions(any()),
    ).thenAnswer((_) async => Right([_version()]));

    await cubit.start();
    await _waitUntil(() => cubit.state is ThesisResultLoaded);

    expect(cubit.state, isA<ThesisResultLoaded>());
    final loaded = cubit.state as ThesisResultLoaded;
    expect(loaded.diffSummary, 'Problem now cites the clinic call.');
    expect(loaded.nextConversation.who, 'clinic ops');
    expect(loaded.applyTimedOut, isFalse);
  });

  test(
    'failed note emits note-failed without opening thesis as home',
    () async {
      when(
        () => getNote(any()),
      ).thenAnswer((_) async => Right(_note(status: AudioNoteStatus.failed)));

      await cubit.start();

      expect(cubit.state, isA<ThesisResultNoteFailed>());
      verifyNever(() => getThesis(any()));
    },
  );

  test('apply timeout still shows the current thesis', () async {
    final completed = _note(status: AudioNoteStatus.completed);
    final stale = _thesis(updatedAt: DateTime.utc(2026, 2, 1));
    when(() => getNote(any())).thenAnswer((_) async => Right(completed));
    when(() => getThesis(any())).thenAnswer((_) async => Right(stale));
    when(() => listVersions(any())).thenAnswer((_) async => const Right([]));

    await cubit.start();
    await _waitUntil(() => cubit.state is ThesisResultLoaded);

    expect(cubit.state, isA<ThesisResultLoaded>());
    final loaded = cubit.state as ThesisResultLoaded;
    expect(loaded.applyTimedOut, isTrue);
  });

  test('get-note failure emits error', () async {
    const failure = ServerFailure('down');
    when(() => getNote(any())).thenAnswer((_) async => const Left(failure));

    await cubit.start();

    expect(cubit.state, const ThesisResultError(failure));
  });
}

Future<void> _waitUntil(bool Function() pred) async {
  for (var i = 0; i < 30; i++) {
    if (pred()) return;
    await Future<void>.delayed(Duration.zero);
  }
}
