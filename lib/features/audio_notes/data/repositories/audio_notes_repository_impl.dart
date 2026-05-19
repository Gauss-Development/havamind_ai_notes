import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:sample/core/error/auth_session_guard.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/audio_notes/data/datasources/audio_notes_local_data_source.dart';
import 'package:sample/features/audio_notes/data/datasources/audio_notes_remote_data_source.dart';
import 'package:sample/features/audio_notes/data/datasources/audio_storage_data_source.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_transcript.dart';
import 'package:sample/features/audio_notes/domain/entities/plan_version.dart';
import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

const _uuid = Uuid();

class AudioNotesRepositoryImpl implements AudioNotesRepository {
  AudioNotesRepositoryImpl({
    required AudioNotesRemoteDataSource remote,
    required AudioStorageDataSource storage,
    required SupabaseClient client,
    AudioNotesLocalDataSource? local,
  }) : _remote = remote,
       _storage = storage,
       _client = client,
       _local = local;

  final AudioNotesRemoteDataSource _remote;
  final AudioStorageDataSource _storage;
  final SupabaseClient _client;
  final AudioNotesLocalDataSource? _local;

  String _defaultTitle() {
    final f = DateFormat('dd.MM.yyyy HH:mm');
    return 'Voice Note ${f.format(DateTime.now())}';
  }

  @override
  Future<Either<Failure, List<AudioNote>>> listNotes({
    int limit = 20,
    int offset = 0,
    List<String>? tagIds,
  }) async {
    try {
      final list = await _remote.listForCurrentUser(
        limit: limit,
        offset: offset,
        tagIds: tagIds,
      );
      if (offset == 0) {
        _local?.cacheNotes(list);
      }
      return Right(list);
    } catch (e) {
      await _maybeHandleAuthError(e);
      if (offset == 0) {
        final cached = _local?.getCachedNotes();
        if (cached != null && cached.isNotEmpty) {
          return Right(cached);
        }
      }
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  Future<void> _maybeHandleAuthError(Object e) async {
    if (isAuthSessionError(e)) {
      await forceSignOutAfterAuthError(_client);
    }
  }

  @override
  Future<Either<Failure, List<AudioNote>>> searchNotesByTitle({
    required String query,
    int limit = 20,
  }) async {
    try {
      final list = await _remote.searchByTitle(query: query, limit: limit);
      return Right(list);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> countNotes() async {
    try {
      final count = await _remote.countForCurrentUser();
      return Right(count);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AudioNote>> getNote(String id) async {
    try {
      final note = await _remote.fetchById(id);
      return Right(note);
    } catch (e) {
      await _maybeHandleAuthError(e);
      // Surface remote-deletion explicitly so callers can transition to a
      // `deleted` UI state. `fetchById` throws with this literal message
      // when `.maybeSingle()` returns null.
      if (e.toString().contains('Note not found')) {
        return const Left(NotFoundFailure('Note not found'));
      }
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AudioNote>> saveRecording({
    required String localFilePath,
    required int durationSeconds,
  }) async {
    return processLocalAudioNote(
      localFilePath: localFilePath,
      durationSeconds: durationSeconds,
    );
  }

  @override
  Future<Either<Failure, AudioNote>> processLocalAudioNote({
    required String localFilePath,
    required int durationSeconds,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const Left(AuthFailure('Authentication required'));
    }

    final noteId = _uuid.v4();
    final userId = user.id;
    final file = File(localFilePath);
    if (!await file.exists()) {
      return const Left(UnexpectedFailure('Recording file not found'));
    }

    final storagePath = '$userId/$noteId/audio.m4a';
    var uploaded = false;
    var rowInserted = false;

    try {
      await _storage.uploadObject(objectPath: storagePath, file: file);
      uploaded = true;

      await _remote.insertDraft(
        id: noteId,
        userId: userId,
        title: _defaultTitle(),
        audioPath: storagePath,
        durationSeconds: durationSeconds,
      );
      rowInserted = true;

      await _remote.updateStatus(
        noteId,
        AudioNoteStatus.uploaded,
        clearLastProcessingError: true,
      );

      await _remote.invokeProcessing(noteId);

      // Local recording is now safely in remote storage and the edge
      // function has been kicked off — purge the on-device copy so the
      // app's documents directory doesn't grow unbounded.
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}

      final note = await _remote.fetchById(noteId);
      return Right(note);
    } catch (e) {
      final msg = _userFacingError(e);
      // Cleanup branches:
      //  * row exists  → mark it failed so the UI shows a retry path
      //  * row missing but file was uploaded → remove the orphan blob;
      //    otherwise Storage accumulates files with no DB reference
      //  * neither happened → nothing to do
      if (rowInserted) {
        try {
          await _remote.updateStatus(
            noteId,
            AudioNoteStatus.failed,
            lastProcessingError: msg,
          );
        } catch (_) {}
      } else if (uploaded) {
        try {
          await _storage.removeObject(storagePath);
        } catch (_) {}
      }
      return Left(ServerFailure(msg));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteNote(String id) async {
    try {
      final note = await _remote.fetchById(id);
      // Drop the DB row first. If we removed Storage first and then the
      // DB call failed (network, RLS conflict), the row would survive
      // pointing at a missing object — UI would show the note forever
      // with a permanently-broken `audio_path`. Reversing the order
      // leaves at worst an orphan Storage object, which is recoverable.
      await _remote.deleteRow(id);
      if (_isRemoteStoragePath(note.audioPath)) {
        try {
          await _storage.removeObject(note.audioPath);
        } catch (_) {
          // Object cleanup is best-effort once the DB row is gone —
          // surface it in logs only, not as a user-facing failure.
        }
      }
      return const Right(unit);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> requestProcessing(String noteId) async {
    try {
      final note = await _remote.fetchById(noteId);

      if (!_isRemoteStoragePath(note.audioPath)) {
        final localPath = _normalizeLocalPath(note.audioPath);
        if (localPath == null) {
          return const Left(
            ServerFailure(
              'Retry is only available for notes with an audio file',
            ),
          );
        }
        final file = File(localPath);
        if (!await file.exists()) {
          return const Left(
            ServerFailure(
              'Local audio file not found. Cannot retry processing',
            ),
          );
        }
        final storagePath = '${note.userId}/$noteId/audio.m4a';
        await _storage.uploadObject(objectPath: storagePath, file: file);
        await _remote.updateAudioPath(noteId, storagePath);
      }

      await _remote.updateStatus(
        noteId,
        AudioNoteStatus.uploaded,
        clearLastProcessingError: true,
      );

      await _remote.invokeProcessing(noteId);
      return const Right(unit);
    } catch (e) {
      final msg = _userFacingError(e);
      try {
        await _remote.updateStatus(
          noteId,
          AudioNoteStatus.failed,
          lastProcessingError: msg,
        );
      } catch (_) {}
      return Left(ServerFailure(msg));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteLocalAudioFile(String noteId) async {
    try {
      final note = await _remote.fetchById(noteId);
      final localPath = _normalizeLocalPath(note.audioPath);
      if (localPath == null) {
        return const Left(
          UnexpectedFailure('No local audio file stored for this note'),
        );
      }

      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
      }
      return const Right(unit);
    } catch (e) {
      return Left(UnexpectedFailure(_userFacingError(e)));
    }
  }

  String _userFacingError(Object e) {
    final s = e.toString();
    const prefix = 'Exception: ';
    return s.startsWith(prefix) ? s.substring(prefix.length) : s;
  }

  @override
  Future<Either<Failure, AudioNoteTranscript?>> getTranscript(
    String noteId,
  ) async {
    try {
      final transcript = await _remote.fetchTranscript(noteId);
      return Right(transcript);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StartupAnalysis?>> getAnalysis(String noteId) async {
    try {
      final analysis = await _remote.fetchAnalysis(noteId);
      return Right(analysis);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateAnalysisField({
    required String noteId,
    required StartupAnalysisEditableField field,
    required String value,
  }) async {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return const Left(UnexpectedFailure('Field cannot be empty'));
    }
    try {
      await _remote.updateAnalysisField(
        noteId: noteId,
        field: field,
        value: normalized,
      );
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(_userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateNoteTitle({
    required String noteId,
    required String title,
  }) async {
    final normalized = title.trim();
    if (normalized.isEmpty) {
      return const Left(UnexpectedFailure('Title cannot be empty'));
    }
    try {
      await _remote.updateTitle(noteId, normalized);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(_userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, int>> getTotalUsageSeconds({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final total = await _remote.getTotalUsageSeconds(from: from, to: to);
      return Right(total);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PlanVersion>>> listPlanVersions(
    String planId,
  ) async {
    try {
      final versions = await _remote.listPlanVersions(planId);
      return Right(versions);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> countRefinementRoundsForNote(
    String audioNoteId,
  ) async {
    try {
      final count = await _remote.countRefinementRoundsForNote(audioNoteId);
      return Right(count);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> restorePlanVersion(
    String versionId,
  ) async {
    try {
      final result = await _remote.restorePlanVersion(versionId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(_userFacingError(e)));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> refinePlanByVoice({
    required String noteId,
    required String localFilePath,
    String? followUpQuestionId,
    String? followUpQuestionText,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const Left(AuthFailure('Authentication required'));
    }

    final file = File(localFilePath);
    if (!await file.exists()) {
      return const Left(UnexpectedFailure('Recording file not found'));
    }

    final storagePath =
        '${user.id}/$noteId/refinement_${DateTime.now().millisecondsSinceEpoch}.m4a';

    try {
      await _storage.uploadObject(objectPath: storagePath, file: file);
      final result = await _remote.invokePlanRefinement(
        planId: noteId,
        audioPath: storagePath,
        followUpQuestionId: followUpQuestionId,
        followUpQuestionText: followUpQuestionText,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(_userFacingError(e)));
    } finally {
      // Cleanup runs whether refinePlan succeeded or failed: on success
      // this frees Storage cost + device space; on failure it prevents
      // orphan refinement audio from piling up. removeObject on a path
      // that was never uploaded is a no-op via the catch.
      try {
        await _storage.removeObject(storagePath);
      } catch (_) {}
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  @override
  Stream<AudioNote?> watchNote(String noteId) {
    return _remote.watchNote(noteId);
  }

  bool _isRemoteStoragePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return false;
    return !trimmed.startsWith('/') &&
        !trimmed.startsWith('file://') &&
        !trimmed.contains(':\\');
  }

  String? _normalizeLocalPath(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('file://')) {
      return Uri.tryParse(trimmed)?.toFilePath();
    }
    if (trimmed.startsWith('/') || trimmed.contains(':\\')) {
      return trimmed;
    }
    return null;
  }
}
