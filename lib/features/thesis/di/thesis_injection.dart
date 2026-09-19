import 'package:get_it/get_it.dart';

import 'package:sample/features/thesis/data/datasources/thesis_remote_data_source.dart';
import 'package:sample/features/thesis/data/repositories/thesis_repository_impl.dart';
import 'package:sample/features/thesis/domain/repositories/thesis_repository.dart';
import 'package:sample/features/thesis/domain/usecases/collect_week_usecase.dart';
import 'package:sample/features/thesis/domain/usecases/get_thesis_usecase.dart';
import 'package:sample/features/thesis/domain/usecases/list_thesis_versions_usecase.dart';
import 'package:sample/features/thesis/domain/usecases/record_week_artifact_share_usecase.dart';
import 'package:sample/features/thesis/domain/usecases/seed_thesis_usecase.dart';
import 'package:sample/features/thesis/presentation/cubit/thesis_home_cubit.dart';
import 'package:sample/features/thesis/presentation/cubit/thesis_result_cubit.dart';
import 'package:sample/features/thesis/presentation/cubit/thesis_week_export_cubit.dart';

void registerThesisDependencies(GetIt getIt) {
  getIt.registerLazySingleton<ThesisRemoteDataSource>(
    () => ThesisRemoteDataSource(getIt()),
  );
  getIt.registerLazySingleton<ThesisRepository>(
    () => ThesisRepositoryImpl(remote: getIt()),
  );
  getIt.registerFactory(() => SeedThesisUseCase(getIt()));
  getIt.registerFactory(() => GetThesisUseCase(getIt()));
  getIt.registerFactory(() => ListThesisVersionsUseCase(getIt()));
  getIt.registerFactory(() => RecordWeekArtifactShareUseCase(getIt()));
  getIt.registerFactory(
    () => CollectWeekUseCase(
      thesisRepository: getIt(),
      audioNotesRepository: getIt(),
    ),
  );
  getIt.registerFactory(
    () => ThesisHomeCubit(seedThesis: getIt(), getThesis: getIt()),
  );
  getIt.registerFactory(
    () => ThesisWeekExportCubit(
      collectWeek: getIt(),
      recordWeekArtifactShare: getIt(),
    ),
  );
  getIt.registerFactoryParam<ThesisResultCubit, String, void>(
    (noteId, _) => ThesisResultCubit(
      noteId: noteId,
      watchNote: getIt(),
      getAudioNote: getIt(),
      getThesis: getIt(),
      listVersions: getIt(),
      requestProcessing: getIt(),
    ),
  );
}
