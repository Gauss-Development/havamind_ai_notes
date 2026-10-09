import 'package:dartz/dartz.dart';

import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/thesis/domain/entities/concept_rewrite.dart';
import 'package:sample/features/thesis/domain/repositories/thesis_repository.dart';

class RewriteConceptUseCase
    implements UseCase<ConceptRewriteResult, RewriteConceptRequest> {
  RewriteConceptUseCase(this._repository);

  final ThesisRepository _repository;

  @override
  Future<Either<Failure, ConceptRewriteResult>> call(
    RewriteConceptRequest params,
  ) {
    return _repository.rewriteConcept(params);
  }
}
