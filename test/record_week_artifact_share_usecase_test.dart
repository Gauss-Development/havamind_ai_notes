import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/repositories/thesis_repository.dart';
import 'package:sample/features/thesis/domain/usecases/record_week_artifact_share_usecase.dart';

class _MockThesisRepository extends Mock implements ThesisRepository {}

void main() {
  late _MockThesisRepository repository;
  late RecordWeekArtifactShareUseCase useCase;

  final thesis = Thesis(
    id: 'thesis-1',
    userId: 'user-1',
    weekArtifactShareCount: 1,
    weekArtifactSharedAt: DateTime.utc(2026, 9, 16),
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 16),
  );

  setUp(() {
    repository = _MockThesisRepository();
    useCase = RecordWeekArtifactShareUseCase(repository);
  });

  test('returns the thesis after a share is recorded', () async {
    when(
      () => repository.recordWeekArtifactShare(),
    ).thenAnswer((_) async => Right(thesis));

    final result = await useCase(const NoParams());

    expect(result, Right(thesis));
    verify(() => repository.recordWeekArtifactShare()).called(1);
  });

  test('forwards a write failure', () async {
    const failure = ServerFailure('down');
    when(
      () => repository.recordWeekArtifactShare(),
    ).thenAnswer((_) async => const Left(failure));

    final result = await useCase(const NoParams());

    expect(result, const Left(failure));
  });
}
