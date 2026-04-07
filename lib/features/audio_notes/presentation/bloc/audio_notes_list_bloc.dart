import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/usecases/list_audio_notes_usecase.dart';

part 'audio_notes_list_bloc.freezed.dart';

@freezed
class AudioNotesListEvent with _$AudioNotesListEvent {
  const factory AudioNotesListEvent.started() = _ListStarted;
  const factory AudioNotesListEvent.refreshed() = _ListRefreshed;
  const factory AudioNotesListEvent.loadMore() = _ListLoadMore;
}

@freezed
class AudioNotesListState with _$AudioNotesListState {
  const factory AudioNotesListState.initial() = _Initial;
  const factory AudioNotesListState.loading() = _Loading;
  const factory AudioNotesListState.loaded(
    List<AudioNote> notes, {
    @Default(false) bool hasReachedEnd,
    @Default(false) bool isLoadingMore,
  }) = _Loaded;
  const factory AudioNotesListState.failure(String message) = _Failure;
}

class AudioNotesListBloc
    extends Bloc<AudioNotesListEvent, AudioNotesListState> {
  AudioNotesListBloc({required ListAudioNotesUseCase listAudioNotes})
    : _listAudioNotes = listAudioNotes,
      super(const AudioNotesListState.initial()) {
    on<_ListStarted>(_onStarted);
    on<_ListRefreshed>(_onRefreshed);
    on<_ListLoadMore>(_onLoadMore);
  }

  static const _pageSize = 20;
  final ListAudioNotesUseCase _listAudioNotes;

  Future<void> _onStarted(
    _ListStarted event,
    Emitter<AudioNotesListState> emit,
  ) async {
    emit(const AudioNotesListState.loading());
    final result = await _listAudioNotes(
      const ListAudioNotesParams(limit: _pageSize),
    );
    result.fold(
      (f) => emit(AudioNotesListState.failure(f.message)),
      (notes) => emit(AudioNotesListState.loaded(
        notes,
        hasReachedEnd: notes.length < _pageSize,
      )),
    );
  }

  Future<void> _onRefreshed(
    _ListRefreshed event,
    Emitter<AudioNotesListState> emit,
  ) async {
    final result = await _listAudioNotes(
      const ListAudioNotesParams(limit: _pageSize),
    );
    result.fold(
      (f) => emit(AudioNotesListState.failure(f.message)),
      (notes) => emit(AudioNotesListState.loaded(
        notes,
        hasReachedEnd: notes.length < _pageSize,
      )),
    );
  }

  Future<void> _onLoadMore(
    _ListLoadMore event,
    Emitter<AudioNotesListState> emit,
  ) async {
    final current = state;
    if (current is! _Loaded || current.hasReachedEnd || current.isLoadingMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    final result = await _listAudioNotes(
      ListAudioNotesParams(limit: _pageSize, offset: current.notes.length),
    );
    result.fold(
      (f) => emit(current.copyWith(isLoadingMore: false)),
      (newNotes) => emit(AudioNotesListState.loaded(
        [...current.notes, ...newNotes],
        hasReachedEnd: newNotes.length < _pageSize,
      )),
    );
  }
}
