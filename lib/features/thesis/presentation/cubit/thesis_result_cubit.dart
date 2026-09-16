import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/usecases/get_audio_note_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/request_processing_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/watch_audio_note_usecase.dart';
import 'package:sample/features/audio_notes/domain/utils/plan_snapshot_diff.dart';
import 'package:sample/features/thesis/domain/entities/next_conversation_script.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';
import 'package:sample/features/thesis/domain/usecases/get_thesis_usecase.dart';
import 'package:sample/features/thesis/domain/usecases/list_thesis_versions_usecase.dart';
import 'package:sample/features/thesis/domain/utils/next_conversation_script.dart';
import 'package:sample/features/thesis/domain/utils/thesis_apply_ready.dart';
import 'package:sample/features/thesis/domain/utils/thesis_readiness.dart';
import 'package:sample/features/thesis/domain/utils/thesis_snapshot_diff.dart';

sealed class ThesisResultState extends Equatable {
  const ThesisResultState();

  @override
  List<Object?> get props => [];
}

class ThesisResultInitial extends ThesisResultState {
  const ThesisResultInitial();
}

class ThesisResultProcessing extends ThesisResultState {
  const ThesisResultProcessing(this.note);

  final AudioNote note;

  @override
  List<Object?> get props => [note];
}

class ThesisResultApplying extends ThesisResultState {
  const ThesisResultApplying(this.note);

  final AudioNote note;

  @override
  List<Object?> get props => [note];
}

class ThesisResultNoteFailed extends ThesisResultState {
  const ThesisResultNoteFailed(this.note);

  final AudioNote note;

  @override
  List<Object?> get props => [note];
}

class ThesisResultLoaded extends ThesisResultState {
  const ThesisResultLoaded({
    required this.note,
    required this.thesis,
    required this.fieldDiff,
    required this.unbackedStakes,
    required this.nextConversation,
    this.diffSummary,
    this.applyTimedOut = false,
  });

  factory ThesisResultLoaded.fromSources({
    required AudioNote note,
    required Thesis thesis,
    required List<ThesisVersion> versions,
    required bool applyTimedOut,
  }) {
    final currentSnap = versions.isNotEmpty
        ? versions.first.thesisSnapshot
        : thesisAsSnapshot(thesis);
    final previousSnap = versions.length >= 2
        ? versions[1].thesisSnapshot
        : null;
    return ThesisResultLoaded(
      note: note,
      thesis: thesis,
      fieldDiff: diffThesisSnapshots(
        previous: previousSnap,
        current: currentSnap,
      ),
      diffSummary: versions.isNotEmpty ? versions.first.diffSummary : null,
      unbackedStakes: selectThesisUnbackedGaps(
        thesis,
        limit: thesisCoreFieldKeys.length,
      ),
      nextConversation: parseNextConversationScript(
        thesis.nextConversationScript,
      ),
      applyTimedOut: applyTimedOut,
    );
  }

  final AudioNote note;
  final Thesis thesis;
  final PlanSnapshotDiff fieldDiff;
  final String? diffSummary;
  final List<ThesisUnbackedGap> unbackedStakes;
  final NextConversationScript nextConversation;
  final bool applyTimedOut;

  @override
  List<Object?> get props => [
    note,
    thesis,
    fieldDiff,
    diffSummary,
    unbackedStakes,
    nextConversation,
    applyTimedOut,
  ];
}

class ThesisResultError extends ThesisResultState {
  const ThesisResultError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Watches a debrief note, then loads thesis diff once apply-debrief lands.
class ThesisResultCubit extends Cubit<ThesisResultState> {
  ThesisResultCubit({
    required String noteId,
    required WatchAudioNoteUseCase watchNote,
    required GetAudioNoteUseCase getAudioNote,
    required GetThesisUseCase getThesis,
    required ListThesisVersionsUseCase listVersions,
    required RequestProcessingUseCase requestProcessing,
    this.applyPollInterval = const Duration(seconds: 2),
    this.applyPollAttempts = 20,
  }) : _noteId = noteId,
       _watchNote = watchNote,
       _getAudioNote = getAudioNote,
       _getThesis = getThesis,
       _listVersions = listVersions,
       _requestProcessing = requestProcessing,
       super(const ThesisResultInitial());

  final String _noteId;
  final WatchAudioNoteUseCase _watchNote;
  final GetAudioNoteUseCase _getAudioNote;
  final GetThesisUseCase _getThesis;
  final ListThesisVersionsUseCase _listVersions;
  final RequestProcessingUseCase _requestProcessing;
  final Duration applyPollInterval;
  final int applyPollAttempts;

  StreamSubscription<AudioNote?>? _noteSub;
  int _applyGeneration = 0;
  var _applyStarted = false;

  Future<void> start() async {
    _applyStarted = false;
    await _noteSub?.cancel();
    _noteSub = _watchNote(_noteId).listen(
      _onNote,
      onError: (Object error) {
        if (isClosed) return;
        emit(ThesisResultError(UnexpectedFailure(error.toString())));
      },
    );

    final result = await _getAudioNote(GetAudioNoteParams(_noteId));
    if (isClosed) return;
    result.fold(
      (failure) => emit(ThesisResultError(failure)),
      _onNote,
    );
  }

  Future<void> retryProcessing() async {
    _applyStarted = false;
    emit(const ThesisResultInitial());
    final result = await _requestProcessing(_noteId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ThesisResultError(failure)),
      (_) {},
    );
  }

  void _onNote(AudioNote? note) {
    if (isClosed) return;
    if (note == null) {
      emit(const ThesisResultError(NotFoundFailure('Note not found')));
      return;
    }

    switch (note.status) {
      case AudioNoteStatus.failed:
        _applyStarted = false;
        emit(ThesisResultNoteFailed(note));
      case AudioNoteStatus.completed:
        if (state is ThesisResultLoaded || _applyStarted) return;
        _applyStarted = true;
        unawaited(_awaitApply(note));
      default:
        if (state is ThesisResultLoaded) return;
        emit(ThesisResultProcessing(note));
    }
  }

  Future<void> _awaitApply(AudioNote note) async {
    final generation = ++_applyGeneration;
    emit(ThesisResultApplying(note));

    for (var i = 0; i < applyPollAttempts; i++) {
      if (isClosed || generation != _applyGeneration) return;
      final done = await _tryEmitLoaded(
        note,
        acceptStale: false,
        generation: generation,
      );
      if (done) return;
      if (i < applyPollAttempts - 1) {
        await Future<void>.delayed(applyPollInterval);
      }
    }

    if (isClosed || generation != _applyGeneration) return;
    await _tryEmitLoaded(note, acceptStale: true, generation: generation);
  }

  Future<bool> _tryEmitLoaded(
    AudioNote note, {
    required bool acceptStale,
    required int generation,
  }) async {
    final thesisResult = await _getThesis(const NoParams());
    if (isClosed || generation != _applyGeneration) return true;

    final thesisFailure = thesisResult.fold<Failure?>((l) => l, (_) => null);
    final thesis = thesisResult.fold<Thesis?>((_) => null, (r) => r);
    if (thesisFailure != null) {
      emit(ThesisResultError(thesisFailure));
      return true;
    }
    if (thesis == null) {
      if (acceptStale) {
        emit(const ThesisResultError(NotFoundFailure('Thesis not found')));
        return true;
      }
      return false;
    }

    final versionsResult = await _listVersions(const ListThesisVersionsParams());
    if (isClosed || generation != _applyGeneration) return true;

    final versionsFailure = versionsResult.fold<Failure?>(
      (l) => l,
      (_) => null,
    );
    final versions = versionsResult.fold<List<ThesisVersion>>(
      (_) => const [],
      (r) => r,
    );
    if (versionsFailure != null) {
      emit(ThesisResultError(versionsFailure));
      return true;
    }

    final ready = isThesisApplyReadyForNote(
      thesis: thesis,
      recentVersions: versions,
      note: note,
    );
    if (!ready && !acceptStale) return false;

    emit(
      ThesisResultLoaded.fromSources(
        note: note,
        thesis: thesis,
        versions: versions,
        applyTimedOut: !ready,
      ),
    );
    return true;
  }

  @override
  Future<void> close() {
    _applyGeneration++;
    _noteSub?.cancel();
    return super.close();
  }
}
