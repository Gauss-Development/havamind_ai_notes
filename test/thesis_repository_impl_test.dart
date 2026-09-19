import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/thesis/data/datasources/thesis_remote_data_source.dart';
import 'package:sample/features/thesis/data/repositories/thesis_repository_impl.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';

class _MockRemote extends Mock implements ThesisRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late ThesisRepositoryImpl repository;

  final thesis = Thesis(
    id: 'thesis-1',
    userId: 'user-1',
    weekArtifactShareCount: 1,
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 16),
  );

  setUp(() {
    remote = _MockRemote();
    repository = ThesisRepositoryImpl(remote: remote);
  });

  test('recordWeekArtifactShare returns the updated thesis', () async {
    when(
      () => remote.recordWeekArtifactShare(),
    ).thenAnswer((_) async => thesis);

    final result = await repository.recordWeekArtifactShare();

    expect(result, Right(thesis));
  });

  test('recordWeekArtifactShare maps a missing thesis', () async {
    when(
      () => remote.recordWeekArtifactShare(),
    ).thenThrow(StateError('No thesis'));

    final result = await repository.recordWeekArtifactShare();

    expect(result, const Left(NotFoundFailure('No thesis')));
  });

  test('recordWeekArtifactShare maps a write error', () async {
    when(
      () => remote.recordWeekArtifactShare(),
    ).thenThrow(Exception('network'));

    final result = await repository.recordWeekArtifactShare();

    expect(result, isA<Left<Failure, Thesis>>());
    expect((result as Left<Failure, Thesis>).value, isA<ServerFailure>());
  });
}
