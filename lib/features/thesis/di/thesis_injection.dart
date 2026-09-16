import 'package:get_it/get_it.dart';

import 'package:sample/features/thesis/data/datasources/thesis_remote_data_source.dart';
import 'package:sample/features/thesis/data/repositories/thesis_repository_impl.dart';
import 'package:sample/features/thesis/domain/repositories/thesis_repository.dart';
import 'package:sample/features/thesis/domain/usecases/seed_thesis_usecase.dart';

void registerThesisDependencies(GetIt getIt) {
  getIt.registerLazySingleton<ThesisRemoteDataSource>(
    () => ThesisRemoteDataSource(getIt()),
  );
  getIt.registerLazySingleton<ThesisRepository>(
    () => ThesisRepositoryImpl(remote: getIt()),
  );
  getIt.registerFactory(() => SeedThesisUseCase(getIt()));
}
