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
import 'package:sample/features/thesis/domain/entities/concept_rewrite.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';
import 'package:sample/features/thesis/domain/usecases/get_thesis_usecase.dart';
import 'package:sample/features/thesis/domain/usecases/list_thesis_versions_usecase.dart';
import 'package:sample/features/thesis/domain/usecases/rewrite_concept_usecase.dart';
import 'package:sample/features/thesis/presentation/concept_result_entry.dart';

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

class ThesisResultRewriting extends ThesisResultState {
  const ThesisResultRewriting(this.note);

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

/// Current speech plus frozen versions. [confirmedLabel] is null until the
/// founder confirms who heard the pitch — the rewrite action stays off.
class ThesisResultAwaitingHearer extends ThesisResultState {
  const ThesisResultAwaitingHearer({
    required this.note,
    required this.thesis,
    required this.versions,
    this.suggestedHearer,
    this.proposedRewrite,
    this.confirmedLabel,
  });

  final AudioNote note;
  final Thesis thesis;
  final List<ThesisVersion> versions;
  final String? suggestedHearer;
  final Map<String, dynamic>? proposedRewrite;
  final String? confirmedLabel;

  bool get canRewrite {
    final label = confirmedLabel?.trim() ?? '';
    return label.isNotEmpty && label.length <= 120;
  }

  @override
  List<Object?> get props => [
    note,
    thesis,
    versions,
    suggestedHearer,
    proposedRewrite,
    confirmedLabel,
  ];
}

class ThesisResultLoaded extends ThesisResultState {
  const ThesisResultLoaded({
    required this.note,
    required this.thesis,
    required this.versions,
    this.rewriteNote,
  });

  final AudioNote note;
  final Thesis thesis;
  final List<ThesisVersion> versions;
  final String? rewriteNote;

  List<ThesisVersion> get heardVersions =>
      versions.where((version) => version.wasHeard).toList();

  @override
  List<Object?> get props => [note, thesis, versions, rewriteNote];
}

class ThesisResultError extends ThesisResultState {
  const ThesisResultError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Watches a note, then either asks who heard the pitch or rewrites unheard.
class ThesisResultCubit extends Cubit<ThesisResultState> {
  ThesisResultCubit({
    required String noteId,
    required this.entry,
    required WatchAudioNoteUseCase watchNote,
    required GetAudioNoteUseCase getAudioNote,
    required GetThesisUseCase getThesis,
    required ListThesisVersionsUseCase listVersions,
    required RequestProcessingUseCase requestProcessing,
    required RewriteConceptUseCase rewriteConcept,
  }) : _noteId = noteId,
       _watchNote = watchNote,
       _getAudioNote = getAudioNote,
       _getThesis = getThesis,
       _listVersions = listVersions,
       _requestProcessing = requestProcessing,
       _rewriteConcept = rewriteConcept,
       super(const ThesisResultInitial());

  final String _noteId;
  final ConceptResultEntry entry;
  final WatchAudioNoteUseCase _watchNote;
  final GetAudioNoteUseCase _getAudioNote;
  final GetThesisUseCase _getThesis;
  final ListThesisVersionsUseCase _listVersions;
  final RequestProcessingUseCase _requestProcessing;
  final RewriteConceptUseCase _rewriteConcept;

  static const _versionLimit = 20;

  StreamSubscription<AudioNote?>? _noteSub;
  var _handled = false;

  Future<void> start() async {
    _handled = false;
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
    result.fold((failure) => emit(ThesisResultError(failure)), _onNote);
  }

  Future<void> retryProcessing() async {
    _handled = false;
    emit(const ThesisResultInitial());
    final result = await _requestProcessing(_noteId);
    if (isClosed) return;
    result.fold((failure) => emit(ThesisResultError(failure)), (_) {});
  }

  void confirmHearer(String raw) {
    final current = state;
    if (current is! ThesisResultAwaitingHearer) return;
    final label = raw.trim();
    if (label.isEmpty || label.length > 120) return;
    emit(
      ThesisResultAwaitingHearer(
        note: current.note,
        thesis: current.thesis,
        versions: current.versions,
        suggestedHearer: current.suggestedHearer,
        proposedRewrite: current.proposedRewrite,
        confirmedLabel: label,
      ),
    );
  }

  void clearHearerConfirmation() {
    final current = state;
    if (current is! ThesisResultAwaitingHearer) return;
    if (current.confirmedLabel == null) return;
    emit(
      ThesisResultAwaitingHearer(
        note: current.note,
        thesis: current.thesis,
        versions: current.versions,
        suggestedHearer: current.suggestedHearer,
        proposedRewrite: current.proposedRewrite,
      ),
    );
  }

  /// Writes the rewrite only after [confirmHearer]. Otherwise this is a no-op.
  Future<void> rewrite() async {
    final current = state;
    if (current is! ThesisResultAwaitingHearer || !current.canRewrite) return;
    final label = current.confirmedLabel!.trim();
    emit(ThesisResultRewriting(current.note));
    final result = await _rewriteConcept(
      RewriteConceptRequest(
        noteId: _noteId,
        heardByLabel: label,
        proposedRewrite: current.proposedRewrite,
      ),
    );
    if (isClosed) return;
    await result.fold((failure) async => emit(ThesisResultError(failure)), (
      applied,
    ) async {
      if (applied is ConceptRewriteNeedsHearer) {
        emit(
          ThesisResultAwaitingHearer(
            note: current.note,
            thesis: current.thesis,
            versions: current.versions,
            suggestedHearer: applied.suggestedHearer ?? current.suggestedHearer,
            proposedRewrite: applied.proposedRewrite.isEmpty
                ? current.proposedRewrite
                : applied.proposedRewrite,
          ),
        );
        return;
      }
      await _emitSpeech(current.note, rewriteNote: _noteOf(applied));
    });
  }

  void _onNote(AudioNote? note) {
    if (isClosed) return;
    if (note == null) {
      emit(const ThesisResultError(NotFoundFailure('Note not found')));
      return;
    }

    switch (note.status) {
      case AudioNoteStatus.failed:
        _handled = false;
        emit(ThesisResultNoteFailed(note));
      case AudioNoteStatus.completed:
        if (_handled ||
            state is ThesisResultLoaded ||
            state is ThesisResultAwaitingHearer) {
          return;
        }
        _handled = true;
        unawaited(_onCompleted(note));
      case AudioNoteStatus.draft:
      case AudioNoteStatus.uploaded:
      case AudioNoteStatus.processingTranscription:
      case AudioNoteStatus.processingAnalysis:
        if (state is ThesisResultLoaded ||
            state is ThesisResultAwaitingHearer) {
          return;
        }
        emit(ThesisResultProcessing(note));
    }
  }

  Future<void> _onCompleted(AudioNote note) async {
    switch (entry) {
      case ConceptResultEntry.view:
        await _emitSpeech(note);
      case ConceptResultEntry.coldPitch:
        await _rewriteUnheard(note);
      case ConceptResultEntry.pitchDebrief:
        await _suggestHearer(note);
    }
  }

  Future<void> _rewriteUnheard(AudioNote note) async {
    emit(ThesisResultRewriting(note));
    final result = await _rewriteConcept(
      RewriteConceptRequest(noteId: _noteId, rewriteUnheard: true),
    );
    if (isClosed) return;
    await result.fold((failure) async => emit(ThesisResultError(failure)), (
      applied,
    ) async {
      if (applied is! ConceptRewriteApplied) {
        emit(
          const ThesisResultError(
            ServerFailure('Cold pitch did not rewrite the concept.'),
          ),
        );
        return;
      }
      await _emitSpeech(note, rewriteNote: applied.rewriteNote);
    });
  }

  Future<void> _suggestHearer(AudioNote note) async {
    final loaded = await _loadSources();
    if (isClosed) return;
    if (loaded == null) return;

    final suggestion = await _rewriteConcept(
      RewriteConceptRequest(noteId: _noteId),
    );
    if (isClosed) return;
    suggestion.fold(
      (_) => emit(
        ThesisResultAwaitingHearer(
          note: note,
          thesis: loaded.thesis,
          versions: loaded.versions,
        ),
      ),
      (result) {
        if (result is ConceptRewriteNeedsHearer) {
          emit(
            ThesisResultAwaitingHearer(
              note: note,
              thesis: loaded.thesis,
              versions: loaded.versions,
              suggestedHearer: result.suggestedHearer,
              proposedRewrite: result.proposedRewrite,
            ),
          );
          return;
        }
        unawaited(_emitSpeech(note, rewriteNote: _noteOf(result)));
      },
    );
  }

  Future<void> _emitSpeech(AudioNote note, {String? rewriteNote}) async {
    final loaded = await _loadSources();
    if (isClosed || loaded == null) return;
    emit(
      ThesisResultLoaded(
        note: note,
        thesis: loaded.thesis,
        versions: loaded.versions,
        rewriteNote: rewriteNote ?? _rewriteNote(loaded.versions),
      ),
    );
  }

  Future<({Thesis thesis, List<ThesisVersion> versions})?>
  _loadSources() async {
    final thesisResult = await _getThesis(const NoParams());
    if (isClosed) return null;
    final thesisFailure = thesisResult.fold<Failure?>((l) => l, (_) => null);
    final thesis = thesisResult.fold<Thesis?>((_) => null, (r) => r);
    if (thesisFailure != null) {
      emit(ThesisResultError(thesisFailure));
      return null;
    }
    if (thesis == null) {
      emit(const ThesisResultError(NotFoundFailure('Thesis not found')));
      return null;
    }

    final versionsResult = await _listVersions(
      const ListThesisVersionsParams(limit: _versionLimit),
    );
    if (isClosed) return null;
    final versionsFailure = versionsResult.fold<Failure?>(
      (l) => l,
      (_) => null,
    );
    if (versionsFailure != null) {
      emit(ThesisResultError(versionsFailure));
      return null;
    }
    final versions = versionsResult.fold<List<ThesisVersion>>(
      (_) => const [],
      (r) => r,
    );
    return (thesis: thesis, versions: versions);
  }

  String? _noteOf(ConceptRewriteResult result) {
    return result is ConceptRewriteApplied ? result.rewriteNote : null;
  }

  String? _rewriteNote(List<ThesisVersion> versions) {
    for (final version in versions) {
      if (version.hearingStatus != HearingStatus.unheard) continue;
      final note = version.diffSummary?.trim();
      if (note != null && note.isNotEmpty) return note;
    }
    return null;
  }

  @override
  Future<void> close() {
    _noteSub?.cancel();
    return super.close();
  }
}
