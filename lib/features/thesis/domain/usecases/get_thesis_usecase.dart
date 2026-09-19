import 'package:dartz/dartz.dart';

import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/repositories/thesis_repository.dart';

/// Reads the account thesis without creating one.
class GetThesisUseCase implements UseCase<Thesis?, NoParams> {
  GetThesisUseCase(this._repository);

  final ThesisRepository _repository;

  @override
  Future<Either<Failure, Thesis?>> call(NoParams params) {
    return _repository.getCurrentThesis();
  }
}
