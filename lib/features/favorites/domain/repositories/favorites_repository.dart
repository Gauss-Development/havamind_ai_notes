import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';

abstract class FavoritesRepository {
  Future<Either<Failure, List<AudioNote>>> listFavorites();

  Future<Either<Failure, Set<String>>> getFavoriteNoteIds();

  Future<Either<Failure, Unit>> toggleFavorite(String noteId);
}
