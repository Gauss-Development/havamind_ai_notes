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
import 'package:sample/features/thesis/domain/entities/concept_rewrite.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';
import 'package:sample/features/thesis/domain/usecases/get_thesis_usecase.dart';
import 'package:sample/features/thesis/domain/usecases/list_thesis_versions_usecase.dart';
import 'package:sample/features/thesis/domain/usecases/rewrite_concept_usecase.dart';
import 'package:sample/features/thesis/presentation/concept_result_entry.dart';
import 'package:sample/features/thesis/presentation/cubit/thesis_result_cubit.dart';

class _MockWatchNote extends Mock implements WatchAudioNoteUseCase {}

class _MockGetNote extends Mock implements GetAudioNoteUseCase {}

class _MockGetThesis extends Mock implements GetThesisUseCase {}

class _MockListVersions extends Mock implements ListThesisVersionsUseCase {}

class _MockRequestProcessing extends Mock implements RequestProcessingUseCase {}

class _MockRewrite extends Mock implements RewriteConceptUseCase {}

AudioNote _note({AudioNoteStatus status = AudioNoteStatus.processingAnalysis}) {
  final at = DateTime.utc(2026, 3, 1, 12);
  return AudioNote(
    id: 'note-1',
    userId: 'user-1',
    title: 'Pitch',
    audioPath: null,
    durationSeconds: 90,
    status: status,
    createdAt: at,
    updatedAt: at,
  );
}

Thesis _thesis() {
  return Thesis(
    id: 'thesis-1',
    userId: 'user-1',
    title: 'Havamind',
    businessModel: 'Clinics pay monthly',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 3, 1, 12),
  );
}

ThesisVersion _heard() {
  return ThesisVersion(
    id: 'v-heard',
    thesisId: 'thesis-1',
    userId: 'user-1',
    roundNumber: 1,
    thesisSnapshot: const {'business_model': 'Clinics pay monthly'},
    transcription: 'the pitch',
    hearingStatus: HearingStatus.heard,
    heardByLabel: 'Маша',
    heardAt: DateTime.utc(2026, 3, 1, 12),
    createdAt: DateTime.utc(2026, 3, 1, 12),
  );
}

void main() {
  late _MockWatchNote watchNote;
  late _MockGetNote getNote;
  late _MockGetThesis getThesis;
  late _MockListVersions listVersions;
  late _MockRequestProcessing requestProcessing;
  late _MockRewrite rewrite;
  late StreamController<AudioNote?> notes;

  setUpAll(() {
    registerFallbackValue(const GetAudioNoteParams('note-1'));
    registerFallbackValue(const NoParams());
    registerFallbackValue(const ListThesisVersionsParams());
    registerFallbackValue(const RewriteConceptRequest(noteId: 'note-1'));
  });

  setUp(() {
    watchNote = _MockWatchNote();
    getNote = _MockGetNote();
    getThesis = _MockGetThesis();
    listVersions = _MockListVersions();
    requestProcessing = _MockRequestProcessing();
    rewrite = _MockRewrite();
    notes = StreamController<AudioNote?>.broadcast();
    when(() => watchNote(any())).thenAnswer((_) => notes.stream);
    when(() => getThesis(any())).thenAnswer((_) async => Right(_thesis()));
    when(() => listVersions(any())).thenAnswer((_) async => Right([_heard()]));
  });

  tearDown(() async {
    await notes.close();
  });

  ThesisResultCubit build(ConceptResultEntry entry) {
    return ThesisResultCubit(
      noteId: 'note-1',
      entry: entry,
      watchNote: watchNote,
      getAudioNote: getNote,
      getThesis: getThesis,
      listVersions: listVersions,
      requestProcessing: requestProcessing,
      rewriteConcept: rewrite,
    );
  }

  test('start emits processing while the note is in the pipeline', () async {
    when(() => getNote(any())).thenAnswer((_) async => Right(_note()));
    final cubit = build(ConceptResultEntry.pitchDebrief);

    await cubit.start();

    expect(cubit.state, isA<ThesisResultProcessing>());
    await cubit.close();
  });

  test(
    'pitch debrief does not rewrite until the hearer is confirmed',
    () async {
      when(() => getNote(any())).thenAnswer(
        (_) async => Right(_note(status: AudioNoteStatus.completed)),
      );
      when(() => rewrite(any())).thenAnswer(
        (_) async => const Right(
          ConceptRewriteNeedsHearer(
            suggestedHearer: 'Маша',
            proposedRewrite: {'business_model': 'Doctors wait 3 weeks'},
          ),
        ),
      );
      final cubit = build(ConceptResultEntry.pitchDebrief);

      await cubit.start();
      await _waitUntil(() => cubit.state is ThesisResultAwaitingHearer);

      final waiting = cubit.state as ThesisResultAwaitingHearer;
      expect(waiting.canRewrite, isFalse);
      expect(waiting.suggestedHearer, 'Маша');
      expect(waiting.thesis.businessModel, 'Clinics pay monthly');
      expect(waiting.versions.single.wasHeard, isTrue);

      await cubit.rewrite();
      verify(() => rewrite(any())).called(1);

      cubit.confirmHearer('   ');
      expect(cubit.state, isA<ThesisResultAwaitingHearer>());
      expect((cubit.state as ThesisResultAwaitingHearer).canRewrite, isFalse);

      cubit.confirmHearer('Маша');
      expect((cubit.state as ThesisResultAwaitingHearer).canRewrite, isTrue);

      when(() => rewrite(any())).thenAnswer(
        (_) async => const Right(ConceptRewriteApplied(rewriteNote: 'Buyer.')),
      );
      when(() => getThesis(any())).thenAnswer(
        (_) async => Right(
          Thesis(
            id: 'thesis-1',
            userId: 'user-1',
            title: 'Havamind',
            businessModel: 'Doctors wait 3 weeks',
            createdAt: DateTime.utc(2026, 1, 1),
            updatedAt: DateTime.utc(2026, 3, 2),
          ),
        ),
      );

      await cubit.rewrite();

      final captured = verify(
        () => rewrite(captureAny()),
      ).captured.cast<RewriteConceptRequest>();
      expect(captured.last.heardByLabel, 'Маша');
      expect(
        captured.last.proposedRewrite?['business_model'],
        'Doctors wait 3 weeks',
      );
      expect(cubit.state, isA<ThesisResultLoaded>());
      final loaded = cubit.state as ThesisResultLoaded;
      expect(loaded.thesis.businessModel, 'Doctors wait 3 weeks');
      expect(loaded.heardVersions.single.heardByLabel, 'Маша');
      await cubit.close();
    },
  );

  test('view shows who heard the speech and does not rewrite', () async {
    when(
      () => getNote(any()),
    ).thenAnswer((_) async => Right(_note(status: AudioNoteStatus.completed)));
    final cubit = build(ConceptResultEntry.view);

    await cubit.start();
    await _waitUntil(() => cubit.state is ThesisResultLoaded);

    final loaded = cubit.state as ThesisResultLoaded;
    expect(loaded.heardVersions.single.heardByLabel, 'Маша');
    verifyNever(() => rewrite(any()));
    await cubit.close();
  });

  test('cold pitch rewrites without a hearer', () async {
    when(
      () => getNote(any()),
    ).thenAnswer((_) async => Right(_note(status: AudioNoteStatus.completed)));
    when(
      () => rewrite(any()),
    ).thenAnswer((_) async => const Right(ConceptRewriteApplied()));
    final cubit = build(ConceptResultEntry.coldPitch);

    await cubit.start();
    await _waitUntil(() => cubit.state is ThesisResultLoaded);

    final captured = verify(
      () => rewrite(captureAny()),
    ).captured.cast<RewriteConceptRequest>();
    expect(captured.single.rewriteUnheard, isTrue);
    expect(captured.single.heardByLabel, isNull);
    await cubit.close();
  });

  test('failed note emits note-failed without opening the concept', () async {
    when(
      () => getNote(any()),
    ).thenAnswer((_) async => Right(_note(status: AudioNoteStatus.failed)));
    final cubit = build(ConceptResultEntry.pitchDebrief);

    await cubit.start();

    expect(cubit.state, isA<ThesisResultNoteFailed>());
    verifyNever(() => getThesis(any()));
    verifyNever(() => rewrite(any()));
    await cubit.close();
  });

  test('get-note failure emits error', () async {
    const failure = ServerFailure('down');
    when(() => getNote(any())).thenAnswer((_) async => const Left(failure));
    final cubit = build(ConceptResultEntry.view);

    await cubit.start();

    expect(cubit.state, const ThesisResultError(failure));
    await cubit.close();
  });
}

Future<void> _waitUntil(bool Function() pred) async {
  for (var i = 0; i < 30; i++) {
    if (pred()) return;
    await Future<void>.delayed(Duration.zero);
  }
}
