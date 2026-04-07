import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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
  StreamSubscription<AudioNote>? _watchSub;

  void _startWatching() {
    _watchSub?.cancel();
    _watchSub = _watchNote(
      _noteId,
    ).listen((note) => add(NoteDetailEvent.noteUpdated(note)), onError: (_) {});
  }

  Future<void> _onLoad(
    _LoadRequested event,
    Emitter<NoteDetailState> emit,
  ) async {
    emit(const NoteDetailState.loading());
    final result = await _getAudioNote(GetAudioNoteParams(event.noteId));
    await result.fold((f) async => emit(NoteDetailState.failure(f.message)), (
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

    if (note.status == AudioNoteStatus.completed) {
      final tRes = await _getTranscript(note.id);
      tRes.fold((_) {}, (t) => transcript = t);
      final aRes = await _getAnalysis(note.id);
      aRes.fold((_) {}, (a) => analysis = a);
    } else {
      // Preserve existing transcript/analysis from current state
      state.maybeWhen(
        loaded: (_, t, a, _) {
          transcript = t;
          analysis = a;
        },
        orElse: () {},
      );
    }

    final localAudioExists = await _localAudioFileExists(note.audioPath);
    emit(_buildLoaded(note, transcript, analysis, localAudioExists));
  }

  Future<void> _onDelete(
    _DeleteRequested event,
    Emitter<NoteDetailState> emit,
  ) async {
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
          (_) => emit(_buildLoaded(note, transcript, analysis, false)),
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
    final localPath = _normalizeLocalPath(audioPath);
    if (localPath == null) return false;
    return File(localPath).exists();
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
