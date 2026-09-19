import 'package:dartz/dartz.dart';

import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_seed_candidate.dart';
import 'package:sample/features/thesis/domain/repositories/thesis_repository.dart';
import 'package:sample/features/thesis/domain/utils/select_best_thesis_seed_candidate.dart';
import 'package:sample/features/thesis/domain/utils/thesis_draft_from_analysis.dart';

/// Creates the account thesis once, from the strongest completed analysis.
///
/// If a thesis already exists it is returned and notes are re-attached so a
/// partial seed can finish. With no completed analysis an empty thesis is
/// inserted so later Home/debrief flows have a row to update.
class SeedThesisUseCase implements UseCase<Thesis, NoParams> {
  SeedThesisUseCase(this._repository);

  final ThesisRepository _repository;

  @override
  Future<Either<Failure, Thesis>> call(NoParams params) async {
    final existingResult = await _repository.getCurrentThesis();
    if (existingResult.isLeft()) {
      return Left((existingResult as Left<Failure, Thesis?>).value);
    }
    final existing = (existingResult as Right<Failure, Thesis?>).value;
    if (existing != null) {
      return _attachAndReturn(existing);
    }

    final candidatesResult = await _repository.listSeedCandidates();
    if (candidatesResult.isLeft()) {
      return Left(
        (candidatesResult as Left<Failure, List<ThesisSeedCandidate>>).value,
      );
    }
    final candidates =
        (candidatesResult as Right<Failure, List<ThesisSeedCandidate>>).value;
    final best = selectBestThesisSeedCandidate(candidates);
    final draft = best == null
        ? const ThesisDraft()
        : thesisDraftFromAnalysis(best.analysis);

    final createdResult = await _repository.createThesis(draft);
    if (createdResult.isLeft()) {
      return createdResult;
    }
    final created = (createdResult as Right<Failure, Thesis>).value;
    return _attachAndReturn(created);
  }

  Future<Either<Failure, Thesis>> _attachAndReturn(Thesis thesis) async {
    final attachResult = await _repository.attachThesisToAllNotes(thesis.id);
    if (attachResult.isLeft()) {
      return Left((attachResult as Left<Failure, Unit>).value);
    }
    return Right(thesis);
  }
}
