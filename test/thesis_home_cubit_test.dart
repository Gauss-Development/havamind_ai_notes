import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/usecases/get_thesis_usecase.dart';
import 'package:sample/features/thesis/domain/usecases/seed_thesis_usecase.dart';
import 'package:sample/features/thesis/presentation/cubit/thesis_home_cubit.dart';

class _MockSeedThesis extends Mock implements SeedThesisUseCase {}

class _MockGetThesis extends Mock implements GetThesisUseCase {}

void main() {
  final thesis = Thesis(
    id: 'thesis-1',
    userId: 'user-1',
    title: 'Havamind',
    problem: 'Founders lose ideas because capture is too slow to keep.',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );

  late _MockSeedThesis seedThesis;
  late _MockGetThesis getThesis;
  late ThesisHomeCubit cubit;

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    seedThesis = _MockSeedThesis();
    getThesis = _MockGetThesis();
    cubit = ThesisHomeCubit(seedThesis: seedThesis, getThesis: getThesis);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('load seeds the thesis and emits loaded', () async {
    when(() => seedThesis(any())).thenAnswer((_) async => Right(thesis));

    await cubit.load();

    expect(cubit.state, isA<ThesisHomeLoaded>());
    final loaded = cubit.state as ThesisHomeLoaded;
    expect(loaded.thesis.id, 'thesis-1');
    expect(loaded.thesis.title, 'Havamind');
    expect(loaded.isBlank, isFalse);
    verify(() => seedThesis(const NoParams())).called(1);
  });

  test('load emits error when seed fails', () async {
    const failure = ServerFailure('seed failed');
    when(() => seedThesis(any())).thenAnswer((_) async => const Left(failure));

    await cubit.load();

    expect(cubit.state, const ThesisHomeError(failure));
  });

  test('refresh reloads the current thesis', () async {
    when(() => seedThesis(any())).thenAnswer((_) async => Right(thesis));
    when(() => getThesis(any())).thenAnswer((_) async => Right(thesis));

    await cubit.load();
    await cubit.refresh();

    expect(cubit.state, isA<ThesisHomeLoaded>());
    verify(() => getThesis(const NoParams())).called(1);
  });

  test('refresh seeds again when the thesis row is missing', () async {
    when(() => seedThesis(any())).thenAnswer((_) async => Right(thesis));
    when(() => getThesis(any())).thenAnswer((_) async => const Right(null));

    await cubit.load();
    await cubit.refresh();

    verify(() => seedThesis(const NoParams())).called(2);
    expect(cubit.state, isA<ThesisHomeLoaded>());
  });

  test('refresh is a no-op while load is in flight', () async {
    when(() => seedThesis(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return Right(thesis);
    });

    final loadFuture = cubit.load();
    await cubit.refresh();
    await loadFuture;

    verifyNever(() => getThesis(any()));
    expect(cubit.state, isA<ThesisHomeLoaded>());
  });
}
