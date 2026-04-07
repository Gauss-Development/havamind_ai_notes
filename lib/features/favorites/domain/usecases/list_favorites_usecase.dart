import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/favorites/domain/repositories/favorites_repository.dart';

class ListFavoritesUseCase implements UseCase<List<AudioNote>, NoParams> {
  ListFavoritesUseCase(this._repository);

  final FavoritesRepository _repository;

  @override
  Future<Either<Failure, List<AudioNote>>> call(NoParams params) {
    return _repository.listFavorites();
  }
}
