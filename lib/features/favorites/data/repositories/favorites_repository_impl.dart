import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/favorites/data/datasources/favorites_remote_data_source.dart';
import 'package:sample/features/favorites/domain/repositories/favorites_repository.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl({required FavoritesRemoteDataSource remote})
    : _remote = remote;

  final FavoritesRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<AudioNote>>> listFavorites() async {
    try {
      final notes = await _remote.listFavoriteNotes();
      return Right(notes);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getFavoriteNoteIds() async {
    try {
      final ids = await _remote.getFavoriteNoteIds();
      return Right(ids);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> toggleFavorite(String noteId) async {
    try {
      final exists = await _remote.isFavorite(noteId);
      if (exists) {
        await _remote.removeFavorite(noteId);
      } else {
        await _remote.addFavorite(noteId);
      }
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
