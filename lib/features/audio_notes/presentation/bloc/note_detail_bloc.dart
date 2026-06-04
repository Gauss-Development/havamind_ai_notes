import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_transcript.dart';
import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/audio_notes/domain/usecases/delete_audio_note_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/delete_local_audio_file_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/get_audio_note_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/get_note_analysis_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/get_note_transcript_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/request_processing_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/update_analysis_field_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/update_note_title_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/watch_audio_note_usecase.dart';

part 'note_detail_bloc.freezed.dart';

@freezed
class NoteDetailEvent with _$NoteDetailEvent {
  const factory NoteDetailEvent.loadRequested(String noteId) = _LoadRequested;
  const factory NoteDetailEvent.deleteRequested() = _DeleteRequested;
  const factory NoteDetailEvent.retryProcessing() = _RetryProcessing;
  const factory NoteDetailEvent.deleteLocalAudioRequested() =
      _DeleteLocalAudioRequested;
  const factory NoteDetailEvent.analysisFieldUpdated({
    required StartupAnalysisEditableField field,
    required String value,
  }) = _AnalysisFieldUpdated;
  const factory NoteDetailEvent.titleUpdated(String title) = _TitleUpdated;
  const factory NoteDetailEvent.noteUpdated(AudioNote note) = _NoteUpdated;
}

@freezed
class NoteDetailState with _$NoteDetailState {
  const factory NoteDetailState.initial() = _NdInitial;
  const factory NoteDetailState.loading() = _NdLoading;
  const factory NoteDetailState.loaded({
    required AudioNote note,
    AudioNoteTranscript? transcript,
    StartupAnalysis? analysis,
    required bool localAudioExists,
  }) = _NdLoaded;
  const factory NoteDetailState.deleted() = _NdDeleted;
  const factory NoteDetailState.failure(String message) = _NdFailure;
}

class NoteDetailBloc extends Bloc<NoteDetailEvent, NoteDetailState> {
  NoteDetailBloc({
    required GetAudioNoteUseCase getAudioNote,
    required DeleteAudioNoteUseCase deleteAudioNote,
    required DeleteLocalAudioFileUseCase deleteLocalAudioFile,
    required GetNoteTranscriptUseCase getTranscript,
    required GetNoteAnalysisUseCase getAnalysis,
    required UpdateAnalysisFieldUseCase updateAnalysisField,
    required UpdateNoteTitleUseCase updateNoteTitle,
    required RequestProcessingUseCase requestProcessing,
    required WatchAudioNoteUseCase watchNote,
    required String noteId,
  }) : _getAudioNote = getAudioNote,
       _deleteAudioNote = deleteAudioNote,
       _deleteLocalAudioFile = deleteLocalAudioFile,
       _getTranscript = getTranscript,
       _getAnalysis = getAnalysis,
       _updateAnalysisField = updateAnalysisField,
       _updateNoteTitle = updateNoteTitle,
       _requestProcessing = requestProcessing,
       _watchNote = watchNote,
       _noteId = noteId,
       super(const NoteDetailState.initial()) {
    on<_LoadRequested>(_onLoad);
    on<_DeleteRequested>(_onDelete);
    on<_RetryProcessing>(_onRetry);
    on<_DeleteLocalAudioRequested>(_onDeleteLocalAudio);
    on<_AnalysisFieldUpdated>(_onAnalysisFieldUpdated);
    on<_TitleUpdated>(_onTitleUpdated);
    on<_NoteUpdated>(_onNoteUpdated);
    add(NoteDetailEvent.loadRequested(noteId));
  }

  final GetAudioNoteUseCase _getAudioNote;
  final DeleteAudioNoteUseCase _deleteAudioNote;
  final DeleteLocalAudioFileUseCase _deleteLocalAudioFile;
  final GetNoteTranscriptUseCase _getTranscript;
  final GetNoteAnalysisUseCase _getAnalysis;
  final UpdateAnalysisFieldUseCase _updateAnalysisField;
  final UpdateNoteTitleUseCase _updateNoteTitle;
  final RequestProcessingUseCase _requestProcessing;
  final WatchAudioNoteUseCase _watchNote;
  final String _noteId;
  StreamSubscription<AudioNote?>? _watchSub;

  // Cache for `_localAudioFileExists`. The file-existence check fires
  // on every realtime row UPDATE; without caching, every event triggers
  // a filesystem syscall even though the audioPath rarely changes after
  // the first upload.
  String? _lastCheckedAudioPath;
  bool _lastLocalAudioExists = false;

  void _startWatching() {
    _watchSub?.cancel();
    _watchSub = _watchNote(_noteId).listen(
      (note) {
        if (note == null) {
          // Empty rows on a row-level `.stream()` subscription means the
          // watched note was deleted remotely. Re-issue load so the
          // `_onLoad` not-found branch can emit the `deleted` state.
          add(NoteDetailEvent.loadRequested(_noteId));
        } else {
          add(NoteDetailEvent.noteUpdated(note));
        }
      },
      onError: (_) {},
    );
  }

  Future<void> _onLoad(
    _LoadRequested event,
    Emitter<NoteDetailState> emit,
  ) async {
    // Always tear down the previous row subscription before a reload so a
    // stale realtime channel cannot enqueue another `loadRequested` after we
    // emit `deleted` (e.g. user delete vs. watch-null race).
    await _watchSub?.cancel();
    _watchSub = null;
    emit(const NoteDetailState.loading());
    final result = await _getAudioNote(GetAudioNoteParams(event.noteId));
    await result.fold((f) async {
      // Distinguish "the note was deleted between load and now" (drives
      // a `deleted` state so the UI pops) from generic errors.
      if (f is NotFoundFailure) {
        emit(const NoteDetailState.deleted());
      } else {
        emit(NoteDetailState.failure(f.message));
      }
    }, (
      note,
    ) async {
      AudioNoteTranscript? transcript;
      StartupAnalysis? analysis;

      if (note.status == AudioNoteStatus.completed) {
        final tRes = await _getTranscript(note.id);
        tRes.fold((_) {}, (t) => transcript = t);
        final aRes = await _getAnalysis(note.id);
        aRes.fold((_) {}, (a) => analysis = a);
      }

      final localAudioExists = await _localAudioFileExists(note.audioPath);
      emit(_buildLoaded(note, transcript, analysis, localAudioExists));

      _startWatching();
    });
  }

  Future<void> _onNoteUpdated(
    _NoteUpdated event,
    Emitter<NoteDetailState> emit,
  ) async {
    final note = event.note;
    AudioNoteTranscript? transcript;
    StartupAnalysis? analysis;
    var wasCompletedBefore = false;

    state.maybeWhen(
      loaded: (currentNote, t, a, _) {
        transcript = t;
        analysis = a;
        wasCompletedBefore = currentNote.status == AudioNoteStatus.completed;
      },
      orElse: () {},
    );

    // Only refetch transcript/analysis on the transition INTO completed
    // (or if we somehow landed in completed state without cached data).
    // Without this guard, every Supabase row UPDATE (e.g. updated_at bumps
    // from refinement edits) would cause two extra network calls per event.
    final needsFetch = note.status == AudioNoteStatus.completed &&
        (!wasCompletedBefore || transcript == null || analysis == null);

    if (needsFetch) {
      final tRes = await _getTranscript(note.id);
      tRes.fold((_) {}, (t) => transcript = t);
      final aRes = await _getAnalysis(note.id);
      aRes.fold((_) {}, (a) => analysis = a);

      // Replica/visibility race: the edge function commits
      // `status='completed'` and `upsert(startup_analyses)` as two
      // separate statements. If we won the race we may see "completed"
      // before the analysis row is readable. Retry once after a short
      // pause so the UI doesn't strand on "No analysis available".
      if (analysis == null) {
        await Future<void>.delayed(const Duration(seconds: 2));
        if (isClosed) return;
        final aRes2 = await _getAnalysis(note.id);
        aRes2.fold((_) {}, (a) => analysis = a);
        if (transcript == null) {
          final tRes2 = await _getTranscript(note.id);
          tRes2.fold((_) {}, (t) => transcript = t);
        }
      }
    }

    final localAudioExists = await _localAudioFileExists(note.audioPath);
    emit(_buildLoaded(note, transcript, analysis, localAudioExists));
  }

  Future<void> _onDelete(
    _DeleteRequested event,
    Emitter<NoteDetailState> emit,
  ) async {
    // Stop watching before the row disappears so we do not enqueue
    // `loadRequested` in the middle of delete and overwrite `deleted`
    // with `loading` (blank / stuck detail shell until the reload finishes).
    await _watchSub?.cancel();
    _watchSub = null;
    emit(const NoteDetailState.loading());
    final result = await _deleteAudioNote(DeleteAudioNoteParams(_noteId));
    result.fold(
      (f) => emit(NoteDetailState.failure(f.message)),
      (_) => emit(const NoteDetailState.deleted()),
    );
  }

  Future<void> _onRetry(
    _RetryProcessing event,
    Emitter<NoteDetailState> emit,
  ) async {
    // Optimistically update UI to show processing
    state.maybeWhen(
      loaded: (note, transcript, analysis, localAudioExists) {
        emit(
          _buildLoaded(
            AudioNote(
              id: note.id,
              userId: note.userId,
              title: note.title,
              audioPath: note.audioPath,
              durationSeconds: note.durationSeconds,
              status: AudioNoteStatus.processingTranscription,
              createdAt: note.createdAt,
              updatedAt: note.updatedAt,
              lastProcessingError: null,
              templateId: note.templateId,
            ),
            transcript,
            analysis,
            localAudioExists,
          ),
        );
      },
      orElse: () {},
    );

    await _requestProcessing(_noteId);
  }

  Future<void> _onDeleteLocalAudio(
    _DeleteLocalAudioRequested event,
    Emitter<NoteDetailState> emit,
  ) async {
    await state.maybeWhen(
      loaded: (note, transcript, analysis, localAudioExists) async {
        if (!localAudioExists) {
          emit(const NoteDetailState.failure('Local audio file already deleted'));
          return;
        }
        final result = await _deleteLocalAudioFile(note.id);
        result.fold(
          (f) => emit(NoteDetailState.failure(f.message)),
          (_) {
            // Invalidate the existence cache so the next realtime update
            // doesn't return stale `true` from the just-deleted path.
            _lastCheckedAudioPath = note.audioPath;
            _lastLocalAudioExists = false;
            emit(_buildLoaded(note, transcript, analysis, false));
          },
        );
      },
      orElse: () async {},
    );
  }

  Future<void> _onTitleUpdated(
    _TitleUpdated event,
    Emitter<NoteDetailState> emit,
  ) async {
    await state.maybeWhen(
      loaded: (note, transcript, analysis, localAudioExists) async {
        final result = await _updateNoteTitle(
          UpdateNoteTitleParams(noteId: note.id, title: event.title),
        );
        result.fold(
          (f) => emit(NoteDetailState.failure(f.message)),
          (_) {
            final updatedNote = AudioNote(
              id: note.id,
              userId: note.userId,
              title: event.title.trim(),
              audioPath: note.audioPath,
              durationSeconds: note.durationSeconds,
              status: note.status,
              createdAt: note.createdAt,
              updatedAt: note.updatedAt,
              lastProcessingError: note.lastProcessingError,
              templateId: note.templateId,
            );
            emit(
              _buildLoaded(
                updatedNote,
                transcript,
                analysis,
                localAudioExists,
              ),
            );
          },
        );
      },
      orElse: () async {},
    );
  }

  Future<void> _onAnalysisFieldUpdated(
    _AnalysisFieldUpdated event,
    Emitter<NoteDetailState> emit,
  ) async {
    await state.maybeWhen(
      loaded: (note, transcript, analysis, localAudioExists) async {
        if (analysis == null) {
          emit(
            const NoteDetailState.failure(
              'Cannot edit: analysis not available yet',
            ),
          );
          return;
        }

        final updateRes = await _updateAnalysisField(
          UpdateAnalysisFieldParams(
            noteId: note.id,
            field: event.field,
            value: event.value,
          ),
        );

        await updateRes.fold(
          (f) async {
            emit(NoteDetailState.failure(f.message));
          },
          (_) async {
            final refreshed = await _getAnalysis(note.id);
            final nextAnalysis = refreshed.fold(
              (_) => _applyAnalysisFieldLocally(
                analysis,
                field: event.field,
                value: event.value.trim(),
              ),
              (value) =>
                  value ??
                  _applyAnalysisFieldLocally(
                    analysis,
                    field: event.field,
                    value: event.value.trim(),
                  ),
            );
            emit(
              _buildLoaded(note, transcript, nextAnalysis, localAudioExists),
            );
          },
        );
      },
      orElse: () async {},
    );
  }

  StartupAnalysis _applyAnalysisFieldLocally(
    StartupAnalysis source, {
    required StartupAnalysisEditableField field,
    required String value,
  }) {
    String? pick(StartupAnalysisEditableField target, String? original) =>
        field == target ? value : original;

    return StartupAnalysis(
      id: source.id,
      audioNoteId: source.audioNoteId,
      userId: source.userId,
      shortSummary: pick(
        StartupAnalysisEditableField.shortSummary,
        source.shortSummary,
      ),
      startupTitle: pick(
        StartupAnalysisEditableField.startupTitle,
        source.startupTitle,
      ),
      problem: pick(StartupAnalysisEditableField.problem, source.problem),
      solution: pick(StartupAnalysisEditableField.solution, source.solution),
      targetAudience: pick(
        StartupAnalysisEditableField.targetAudience,
        source.targetAudience,
      ),
      businessModel: pick(
        StartupAnalysisEditableField.businessModel,
        source.businessModel,
      ),
      keyMetrics: pick(
        StartupAnalysisEditableField.keyMetrics,
        source.keyMetrics,
      ),
      advantages: pick(
        StartupAnalysisEditableField.advantages,
        source.advantages,
      ),
      risksGaps: pick(StartupAnalysisEditableField.risksGaps, source.risksGaps),
      followUpQuestions: source.followUpQuestions,
      marketPotentialScore: source.marketPotentialScore,
      technicalComplexityScore: source.technicalComplexityScore,
      createdAt: source.createdAt,
    );
  }

  NoteDetailState _buildLoaded(
    AudioNote note,
    AudioNoteTranscript? transcript,
    StartupAnalysis? analysis,
    bool localAudioExists,
  ) {
    return NoteDetailState.loaded(
      note: note,
      transcript: transcript,
      analysis: analysis,
      localAudioExists: localAudioExists,
    );
  }

  Future<bool> _localAudioFileExists(String audioPath) async {
    if (_lastCheckedAudioPath == audioPath) {
      return _lastLocalAudioExists;
    }
    final localPath = _normalizeLocalPath(audioPath);
    bool exists;
    if (localPath == null) {
      exists = false;
    } else {
      exists = await File(localPath).exists();
    }
    _lastCheckedAudioPath = audioPath;
    _lastLocalAudioExists = exists;
    return exists;
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

  @override
  Future<void> close() async {
    await _watchSub?.cancel();
    return super.close();
  }
}
