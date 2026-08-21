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
  const factory AudioNotesListEvent.tagFilterChanged(List<String> tagIds) =
      _TagFilterChanged;
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
    on<_TagFilterChanged>(_onTagFilterChanged);
  }

  static const _pageSize = 20;
  final ListAudioNotesUseCase _listAudioNotes;
  List<String> _activeTagIds = [];

  Future<void> _onStarted(
    _ListStarted event,
    Emitter<AudioNotesListState> emit,
  ) async {
    emit(const AudioNotesListState.loading());
    final tagFilter = _activeTagIds.isNotEmpty ? _activeTagIds : null;
    final result = await _listAudioNotes(
      ListAudioNotesParams(limit: _pageSize, tagIds: tagFilter),
    );
    result.fold(
      (f) => emit(AudioNotesListState.failure(f.message)),
      (notes) => emit(
        AudioNotesListState.loaded(
          notes,
          hasReachedEnd: notes.length < _pageSize,
        ),
      ),
    );
  }

  Future<void> _onRefreshed(
    _ListRefreshed event,
    Emitter<AudioNotesListState> emit,
  ) async {
    final tagFilter = _activeTagIds.isNotEmpty ? _activeTagIds : null;
    final result = await _listAudioNotes(
      ListAudioNotesParams(limit: _pageSize, tagIds: tagFilter),
    );
    result.fold(
      (f) => emit(AudioNotesListState.failure(f.message)),
      (notes) => emit(
        AudioNotesListState.loaded(
          notes,
          hasReachedEnd: notes.length < _pageSize,
        ),
      ),
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
    final tagFilter = _activeTagIds.isNotEmpty ? _activeTagIds : null;
    final result = await _listAudioNotes(
      ListAudioNotesParams(
        limit: _pageSize,
        offset: current.notes.length,
        tagIds: tagFilter,
      ),
    );
    result.fold(
      (f) => emit(current.copyWith(isLoadingMore: false)),
      (newNotes) => emit(
        AudioNotesListState.loaded([
          ...current.notes,
          ...newNotes,
        ], hasReachedEnd: newNotes.length < _pageSize),
      ),
    );
  }

  Future<void> _onTagFilterChanged(
    _TagFilterChanged event,
    Emitter<AudioNotesListState> emit,
  ) async {
    _activeTagIds = event.tagIds;
    emit(const AudioNotesListState.loading());
    final tagFilter = _activeTagIds.isNotEmpty ? _activeTagIds : null;
    final result = await _listAudioNotes(
      ListAudioNotesParams(limit: _pageSize, tagIds: tagFilter),
    );
    result.fold(
      (f) => emit(AudioNotesListState.failure(f.message)),
      (notes) => emit(
        AudioNotesListState.loaded(
          notes,
          hasReachedEnd: notes.length < _pageSize,
        ),
      ),
    );
  }
}
