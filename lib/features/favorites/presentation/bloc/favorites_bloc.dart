import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/favorites/domain/usecases/get_favorite_ids_usecase.dart';
import 'package:sample/features/favorites/domain/usecases/list_favorites_usecase.dart';
import 'package:sample/features/favorites/domain/usecases/toggle_favorite_usecase.dart';

part 'favorites_bloc.freezed.dart';

@freezed
class FavoritesEvent with _$FavoritesEvent {
  const factory FavoritesEvent.started() = _Started;
  const factory FavoritesEvent.refreshed() = _Refreshed;
  const factory FavoritesEvent.toggled(String noteId) = _Toggled;
}

@freezed
class FavoritesState with _$FavoritesState {
  const factory FavoritesState.initial() = _Initial;
  const factory FavoritesState.loading() = _Loading;
  const factory FavoritesState.loaded({
    required List<AudioNote> notes,
    required Set<String> favoriteIds,
  }) = _Loaded;
  const factory FavoritesState.failure(String message) = _Failure;
}

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc({
    required ListFavoritesUseCase listFavorites,
    required GetFavoriteIdsUseCase getFavoriteIds,
    required ToggleFavoriteUseCase toggleFavorite,
  })  : _listFavorites = listFavorites,
        _getFavoriteIds = getFavoriteIds,
        _toggleFavorite = toggleFavorite,
        super(const FavoritesState.initial()) {
    on<_Started>(_onStarted);
    on<_Refreshed>(_onRefreshed);
    on<_Toggled>(_onToggled);
  }

  final ListFavoritesUseCase _listFavorites;
  final GetFavoriteIdsUseCase _getFavoriteIds;
  final ToggleFavoriteUseCase _toggleFavorite;

  Future<void> _onStarted(
    _Started event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(const FavoritesState.loading());
    await _fetchAll(emit);
  }

  Future<void> _onRefreshed(
    _Refreshed event,
    Emitter<FavoritesState> emit,
  ) async {
    await _fetchAll(emit);
  }

  Future<void> _onToggled(
    _Toggled event,
    Emitter<FavoritesState> emit,
  ) async {
    final noteId = event.noteId;

    // Optimistic update: flip the ID in/out of the set immediately.
    state.maybeWhen(
      loaded: (notes, favoriteIds) {
        final updatedIds = Set<String>.from(favoriteIds);
        if (updatedIds.contains(noteId)) {
          updatedIds.remove(noteId);
        } else {
          updatedIds.add(noteId);
        }
        emit(FavoritesState.loaded(notes: notes, favoriteIds: updatedIds));
      },
      orElse: () {},
    );

    final result = await _toggleFavorite(ToggleFavoriteParams(noteId));
    result.fold(
      (failure) {
        // Revert optimistic update on failure by refreshing.
        add(const FavoritesEvent.refreshed());
      },
      (_) {
        // Refresh to get the authoritative list of notes & IDs.
        add(const FavoritesEvent.refreshed());
      },
    );
  }

  Future<void> _fetchAll(Emitter<FavoritesState> emit) async {
    final idsResult = await _getFavoriteIds(const NoParams());
    final notesResult = await _listFavorites(const NoParams());

    final ids = idsResult.fold((_) => <String>{}, (ids) => ids);
    notesResult.fold(
      (f) => emit(FavoritesState.failure(f.message)),
      (notes) => emit(FavoritesState.loaded(notes: notes, favoriteIds: ids)),
    );
  }
}
