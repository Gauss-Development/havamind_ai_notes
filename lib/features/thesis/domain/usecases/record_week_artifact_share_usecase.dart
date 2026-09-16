import 'package:dartz/dartz.dart';

import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/repositories/thesis_repository.dart';

/// Increments the weekly-artifact share counter. Not used for copy.
class RecordWeekArtifactShareUseCase implements UseCase<Thesis, NoParams> {
  RecordWeekArtifactShareUseCase(this._repository);

  final ThesisRepository _repository;

  @override
  Future<Either<Failure, Thesis>> call(NoParams params) {
    return _repository.recordWeekArtifactShare();
  }
}
