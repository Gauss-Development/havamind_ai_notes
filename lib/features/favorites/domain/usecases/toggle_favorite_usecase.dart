import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/favorites/domain/repositories/favorites_repository.dart';

class ToggleFavoriteParams {
  const ToggleFavoriteParams(this.noteId);
  final String noteId;
}

class ToggleFavoriteUseCase implements UseCase<Unit, ToggleFavoriteParams> {
  ToggleFavoriteUseCase(this._repository);

  final FavoritesRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(ToggleFavoriteParams params) {
    return _repository.toggleFavorite(params.noteId);
  }
}
