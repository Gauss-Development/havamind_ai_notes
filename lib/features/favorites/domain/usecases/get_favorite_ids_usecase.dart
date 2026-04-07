import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/favorites/domain/repositories/favorites_repository.dart';

class GetFavoriteIdsUseCase implements UseCase<Set<String>, NoParams> {
  GetFavoriteIdsUseCase(this._repository);

  final FavoritesRepository _repository;

  @override
  Future<Either<Failure, Set<String>>> call(NoParams params) {
    return _repository.getFavoriteNoteIds();
  }
}
