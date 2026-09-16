import 'package:dartz/dartz.dart';

import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';
import 'package:sample/features/thesis/domain/repositories/thesis_repository.dart';

class ListThesisVersionsParams {
  const ListThesisVersionsParams({this.limit = 2});

  final int limit;
}

/// Newest [ThesisVersion] rows first, for field diff after a debrief.
class ListThesisVersionsUseCase
    implements UseCase<List<ThesisVersion>, ListThesisVersionsParams> {
  ListThesisVersionsUseCase(this._repository);

  final ThesisRepository _repository;

  @override
  Future<Either<Failure, List<ThesisVersion>>> call(
    ListThesisVersionsParams params,
  ) {
    return _repository.listRecentVersions(limit: params.limit);
  }
}
