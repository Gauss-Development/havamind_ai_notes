import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/audio_notes/data/datasources/audio_notes_remote_data_source.dart';
import 'package:sample/features/audio_notes/data/datasources/audio_storage_data_source.dart';
import 'package:sample/features/audio_notes/data/repositories/audio_notes_repository_impl.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockRemote extends Mock implements AudioNotesRemoteDataSource {}

class _MockStorage extends Mock implements AudioStorageDataSource {}

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrue extends Mock implements GoTrueClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(File('fallback.m4a'));
    registerFallbackValue(AudioNoteStatus.draft);
  });

  late _MockRemote remote;
  late _MockStorage storage;
  late _MockSupabaseClient client;
  late _MockGoTrue auth;
  late AudioNotesRepositoryImpl repo;

  const testUser = User(
    id: 'user-1',
    appMetadata: {},
    userMetadata: null,
    aud: 'authenticated',
    createdAt: '2025-01-01T00:00:00Z',
  );

  AudioNote noteForId(String id) => AudioNote(
    id: id,
    userId: 'user-1',
    title: 't',
    audioPath: 'user-1/$id/audio.m4a',
    durationSeconds: 10,
    status: AudioNoteStatus.uploaded,
    createdAt: DateTime.utc(2025),
    updatedAt: DateTime.utc(2025),
  );

  setUp(() {
    remote = _MockRemote();
    storage = _MockStorage();
    client = _MockSupabaseClient();
    auth = _MockGoTrue();
    when(() => client.auth).thenReturn(auth);
    repo = AudioNotesRepositoryImpl(
      remote: remote,
      storage: storage,
      client: client,
    );
  });

  group('saveRecording', () {
    test('uploads to storage and invokes edge function', () async {
      when(() => auth.currentUser).thenReturn(testUser);
      final dir = Directory.systemTemp.createTempSync('audio_notes_test_');
      final file = File('${dir.path}/rec.m4a')..writeAsStringSync('x');

      when(
        () => storage.uploadObject(
          objectPath: any(named: 'objectPath'),
          file: any(named: 'file'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => remote.insertDraft(
          id: any(named: 'id'),
          userId: any(named: 'userId'),
          title: any(named: 'title'),
          audioPath: any(named: 'audioPath'),
          durationSeconds: any(named: 'durationSeconds'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => remote.updateStatus(
          any(),
          any(),
          clearLastProcessingError: any(named: 'clearLastProcessingError'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => remote.invokeProcessing(any()),
      ).thenAnswer((_) async {});

      when(() => remote.fetchById(any())).thenAnswer((invocation) async {
        final id = invocation.positionalArguments[0] as String;
        return noteForId(id);
      });

      final result = await repo.saveRecording(
        localFilePath: file.path,
        durationSeconds: 10,
      );

      expect(result.isRight(), true);
      verify(
        () => storage.uploadObject(
          objectPath: any(named: 'objectPath'),
          file: any(named: 'file'),
        ),
      ).called(1);
      verify(() => remote.invokeProcessing(any())).called(1);

      await dir.delete(recursive: true);
    });

    test('marks failed when edge function throws', () async {
      when(() => auth.currentUser).thenReturn(testUser);
      final dir =
          Directory.systemTemp.createTempSync('audio_notes_test_fail_');
      final file = File('${dir.path}/rec.m4a')..writeAsStringSync('x');

      when(
        () => storage.uploadObject(
          objectPath: any(named: 'objectPath'),
          file: any(named: 'file'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => remote.insertDraft(
          id: any(named: 'id'),
          userId: any(named: 'userId'),
          title: any(named: 'title'),
          audioPath: any(named: 'audioPath'),
          durationSeconds: any(named: 'durationSeconds'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => remote.updateStatus(
          any(),
          any(),
          clearLastProcessingError: any(named: 'clearLastProcessingError'),
          lastProcessingError: any(named: 'lastProcessingError'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => remote.invokeProcessing(any()),
      ).thenThrow(Exception('edge function error'));

      final result = await repo.saveRecording(
        localFilePath: file.path,
        durationSeconds: 5,
      );

      expect(result.isLeft(), true);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected Left'),
      );

      await dir.delete(recursive: true);
    });

    test('returns AuthFailure when not signed in', () async {
      when(() => auth.currentUser).thenReturn(null);
      final result = await repo.saveRecording(
        localFilePath: '/tmp/missing.m4a',
        durationSeconds: 1,
      );
      expect(
        result,
        const Left<Failure, AudioNote>(
          AuthFailure('Authentication required'),
        ),
      );
    });
  });

  group('deleteNote', () {
    test('removes storage object then row', () async {
      final n = noteForId('note-1');
      when(() => remote.fetchById('note-1')).thenAnswer((_) async => n);
      when(() => storage.removeObject(n.audioPath)).thenAnswer((_) async {});
      when(() => remote.deleteRow('note-1')).thenAnswer((_) async {});

      final result = await repo.deleteNote('note-1');

      expect(result, const Right<Failure, Unit>(unit));
      verify(() => remote.fetchById('note-1')).called(1);
      verify(() => storage.removeObject(n.audioPath)).called(1);
      verify(() => remote.deleteRow('note-1')).called(1);
    });
  });
}
