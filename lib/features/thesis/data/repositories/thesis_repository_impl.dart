import 'package:dartz/dartz.dart';

import 'package:sample/core/error/failure.dart';
import 'package:sample/features/thesis/data/datasources/thesis_remote_data_source.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_seed_candidate.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';
import 'package:sample/features/thesis/domain/repositories/thesis_repository.dart';

class ThesisRepositoryImpl implements ThesisRepository {
  ThesisRepositoryImpl({required ThesisRemoteDataSource remote})
    : _remote = remote;

  final ThesisRemoteDataSource _remote;

  @override
  Future<Either<Failure, Thesis?>> getCurrentThesis() async {
    try {
      return Right(await _remote.fetchCurrent());
    } catch (e) {
      return Left(_mapReadError(e));
    }
  }

  @override
  Future<Either<Failure, List<ThesisSeedCandidate>>>
  listSeedCandidates() async {
    try {
      return Right(await _remote.listSeedCandidates());
    } catch (e) {
      return Left(_mapReadError(e));
    }
  }

  @override
  Future<Either<Failure, Thesis>> createThesis(ThesisDraft draft) async {
    try {
      return Right(await _remote.insertThesis(draft));
    } catch (e) {
      return Left(_mapWriteError(e));
    }
  }

  @override
  Future<Either<Failure, Unit>> attachThesisToAllNotes(String thesisId) async {
    try {
      await _remote.attachThesisToAllNotes(thesisId);
      return const Right(unit);
    } catch (e) {
      return Left(_mapWriteError(e));
    }
  }

  @override
  Future<Either<Failure, List<ThesisVersion>>> listRecentVersions({
    int limit = 2,
  }) async {
    try {
      return Right(await _remote.fetchRecentVersions(limit: limit));
    } catch (e) {
      return Left(_mapReadError(e));
    }
  }

  @override
  Future<Either<Failure, Thesis>> recordWeekArtifactShare() async {
    try {
      return Right(await _remote.recordWeekArtifactShare());
    } catch (e) {
      if (e.toString().contains('No thesis')) {
        return const Left(NotFoundFailure('No thesis'));
      }
      return Left(_mapWriteError(e));
    }
  }

  Failure _mapReadError(Object error) {
    if (_isNotSignedIn(error)) {
      return const AuthFailure('Not signed in');
    }
    return UnexpectedFailure(error.toString());
  }

  Failure _mapWriteError(Object error) {
    if (_isNotSignedIn(error)) {
      return const AuthFailure('Not signed in');
    }
    return ServerFailure(error.toString());
  }

  bool _isNotSignedIn(Object error) {
    return error.toString().contains('Not signed in');
  }
}
