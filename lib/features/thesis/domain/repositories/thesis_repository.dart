import 'package:dartz/dartz.dart';

import 'package:sample/core/error/failure.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_seed_candidate.dart';

abstract class ThesisRepository {
  /// The current user's thesis, or `null` if none has been created yet.
  Future<Either<Failure, Thesis?>> getCurrentThesis();

  /// Completed notes that have a `startup_analyses` row, for seed selection.
  Future<Either<Failure, List<ThesisSeedCandidate>>> listSeedCandidates();

  Future<Either<Failure, Thesis>> createThesis(ThesisDraft draft);

  /// Sets `audio_notes.thesis_id` on every note owned by the current user.
  Future<Either<Failure, Unit>> attachThesisToAllNotes(String thesisId);
}
