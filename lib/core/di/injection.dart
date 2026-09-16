import 'package:get_it/get_it.dart';
import 'package:sample/core/config/environment_config.dart';
import 'package:sample/core/theme/app_theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sample/features/auth/data/datasources/profile_remote_data_source.dart';
import 'package:sample/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:sample/features/auth/domain/repositories/auth_repository.dart';
import 'package:sample/features/auth/domain/usecases/get_initial_session_usecase.dart';
import 'package:sample/features/auth/domain/usecases/observe_auth_state_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_in_with_apple_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_in_with_email_password_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:sample/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:sample/features/auth/domain/usecases/sign_up_with_email_password_usecase.dart';
import 'package:sample/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sample/features/audio_notes/data/datasources/audio_notes_local_data_source.dart';
import 'package:sample/features/audio_notes/data/datasources/audio_notes_remote_data_source.dart';
import 'package:sample/features/audio_notes/data/datasources/audio_storage_data_source.dart';
import 'package:sample/features/audio_notes/data/repositories/audio_notes_repository_impl.dart';
import 'package:sample/features/audio_notes/data/services/audio_recording_service.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';
import 'package:sample/features/audio_notes/domain/usecases/count_audio_notes_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/delete_audio_note_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/get_audio_note_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/get_note_analysis_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/get_note_transcript_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/list_audio_notes_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/process_local_audio_note_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/request_processing_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/save_audio_recording_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/search_notes_by_title_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/search_notes_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/update_analysis_field_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/update_note_title_usecase.dart';
import 'package:sample/features/audio_notes/domain/usecases/watch_audio_note_usecase.dart';
import 'package:sample/features/audio_notes/presentation/bloc/audio_notes_list_bloc.dart';
import 'package:sample/features/audio_notes/presentation/cubit/notes_count_cubit.dart';
import 'package:sample/features/audio_notes/presentation/cubit/plan_readiness_home_cubit.dart';
import 'package:sample/features/audio_notes/presentation/bloc/note_detail_bloc.dart';
import 'package:sample/features/audio_notes/presentation/bloc/plan_refinement_cubit.dart';
import 'package:sample/features/audio_notes/presentation/bloc/plan_version_history_cubit.dart';
import 'package:sample/features/audio_notes/presentation/bloc/recording_bloc.dart';
import 'package:sample/features/favorites/data/datasources/favorites_remote_data_source.dart';
import 'package:sample/features/favorites/data/repositories/favorites_repository_impl.dart';
import 'package:sample/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:sample/features/favorites/domain/usecases/get_favorite_ids_usecase.dart';
import 'package:sample/features/favorites/domain/usecases/list_favorites_usecase.dart';
import 'package:sample/features/favorites/domain/usecases/toggle_favorite_usecase.dart';
import 'package:sample/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:sample/features/subscription/data/datasources/revenuecat_data_source.dart';
import 'package:sample/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:sample/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:sample/features/subscription/domain/usecases/get_current_usage_usecase.dart';
import 'package:sample/features/subscription/domain/usecases/get_subscription_status_usecase.dart';
import 'package:sample/features/subscription/domain/usecases/get_offerings_usecase.dart';
import 'package:sample/features/subscription/domain/usecases/purchase_package_usecase.dart';
import 'package:sample/features/subscription/domain/usecases/restore_purchases_usecase.dart';
import 'package:sample/features/subscription/presentation/cubit/subscription_cubit.dart';
import 'package:sample/features/tags/data/datasources/tags_remote_data_source.dart';
import 'package:sample/features/tags/data/repositories/tags_repository_impl.dart';
import 'package:sample/features/tags/domain/repositories/tags_repository.dart';
import 'package:sample/features/tags/presentation/bloc/tags_cubit.dart';
import 'package:sample/features/thesis/di/thesis_injection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);

  getIt.registerLazySingleton<AppThemeCubit>(() => AppThemeCubit(getIt()));

  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSource(getIt()),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(profileRemote: getIt(), client: getIt()),
  );

  getIt.registerFactory(() => GetInitialSessionUseCase(getIt()));
  getIt.registerFactory(() => SignInWithGoogleUseCase(getIt()));
  getIt.registerFactory(() => SignInWithAppleUseCase(getIt()));
  getIt.registerFactory(() => SignInWithEmailPasswordUseCase(getIt()));
  getIt.registerFactory(() => SignUpWithEmailPasswordUseCase(getIt()));
  getIt.registerFactory(() => SignOutUseCase(getIt()));
  getIt.registerFactory(() => DeleteAccountUseCase(getIt()));
  getIt.registerFactory(() => ObserveAuthStateUseCase(getIt()));

  getIt.registerFactory(
    () => AuthBloc(
      getInitialSession: getIt(),
      signInWithGoogle: getIt(),
      signInWithApple: getIt(),
      signInWithEmailPassword: getIt(),
      signUpWithEmailPassword: getIt(),
      signOut: getIt(),
      observeAuthState: getIt(),
    ),
  );

  getIt.registerLazySingleton<AudioNotesRemoteDataSource>(
    () => AudioNotesRemoteDataSource(getIt()),
  );
  getIt.registerLazySingleton<AudioStorageDataSource>(
    () => AudioStorageDataSource(getIt()),
  );
  getIt.registerLazySingleton<AudioNotesLocalDataSource>(
    () => AudioNotesLocalDataSource(getIt()),
  );

  getIt.registerLazySingleton<AudioNotesRepository>(
    () => AudioNotesRepositoryImpl(
      remote: getIt(),
      storage: getIt(),
      client: getIt(),
      local: getIt(),
    ),
  );

  // Singleton: the underlying `AudioRecorder` owns the device microphone
  // and cannot be safely instantiated twice. Sharing one instance means
  // a second consumer that tries to start while the first is still
  // recording will fail loudly instead of silently fighting over the mic.
  getIt.registerLazySingleton(() => AudioRecordingService());
  getIt.registerFactory(() => ListAudioNotesUseCase(getIt()));
  getIt.registerFactory(() => SearchNotesByTitleUseCase(getIt()));
  getIt.registerFactory(() => SearchNotesUseCase(getIt()));
  getIt.registerFactory(() => CountAudioNotesUseCase(getIt()));
  getIt.registerFactory(() => GetAudioNoteUseCase(getIt()));
  getIt.registerFactory(() => SaveAudioRecordingUseCase(getIt()));
  getIt.registerFactory(() => ProcessLocalAudioNoteUseCase(getIt()));
  getIt.registerFactory(() => DeleteAudioNoteUseCase(getIt()));
  getIt.registerFactory(() => RequestProcessingUseCase(getIt()));
  getIt.registerFactory(() => GetNoteTranscriptUseCase(getIt()));
  getIt.registerFactory(() => GetNoteAnalysisUseCase(getIt()));
  getIt.registerFactory(() => UpdateAnalysisFieldUseCase(getIt()));
  getIt.registerFactory(() => UpdateNoteTitleUseCase(getIt()));
  getIt.registerFactory(() => WatchAudioNoteUseCase(getIt()));

  getIt.registerFactory(() => AudioNotesListBloc(listAudioNotes: getIt()));
  getIt.registerFactory(() => NotesCountCubit(countNotes: getIt()));
  getIt.registerFactory(() => PlanReadinessHomeCubit(getAnalysis: getIt()));
  getIt.registerFactory(
    () => RecordingBloc(
      recordingService: getIt(),
      processLocalAudioNote: getIt(),
      getCurrentUsage: getIt(),
    ),
  );
  getIt.registerFactory(() => PlanVersionHistoryCubit(repository: getIt()));
  getIt.registerFactory(
    () => PlanRefinementCubit(
      recordingService: getIt(),
      repository: getIt(),
      getCurrentUsage: getIt(),
    ),
  );
  getIt.registerFactoryParam<NoteDetailBloc, String, void>(
    (noteId, _) => NoteDetailBloc(
      getAudioNote: getIt(),
      deleteAudioNote: getIt(),
      getTranscript: getIt(),
      getAnalysis: getIt(),
      updateAnalysisField: getIt(),
      updateNoteTitle: getIt(),
      requestProcessing: getIt(),
      watchNote: getIt(),
      noteId: noteId,
    ),
  );

  // ── Favorites ──────────────────────────────────────────────────────────

  getIt.registerLazySingleton<FavoritesRemoteDataSource>(
    () => FavoritesRemoteDataSource(getIt()),
  );
  getIt.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(remote: getIt()),
  );

  getIt.registerFactory(() => ListFavoritesUseCase(getIt()));
  getIt.registerFactory(() => GetFavoriteIdsUseCase(getIt()));
  getIt.registerFactory(() => ToggleFavoriteUseCase(getIt()));

  getIt.registerFactory(
    () => FavoritesBloc(
      listFavorites: getIt(),
      getFavoriteIds: getIt(),
      toggleFavorite: getIt(),
    ),
  );

  // ── Tags ────────────────────────────────────────────────────────────────

  getIt.registerLazySingleton<TagsRemoteDataSource>(
    () => TagsRemoteDataSource(getIt()),
  );
  getIt.registerLazySingleton<TagsRepository>(
    () => TagsRepositoryImpl(remote: getIt()),
  );
  getIt.registerFactory(() => TagsCubit(repository: getIt()));

  // ── Thesis ───────────────────────────────────────────────────────────────

  registerThesisDependencies(getIt);

  // ── Subscription ─────────────────────────────────────────────────────────

  getIt.registerLazySingleton<RevenueCatDataSource>(
    () => RevenueCatDataSource(),
  );
  getIt.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(
      dataSource: getIt(),
      apiKey: EnvironmentConfig.instance.revenueCatApiKey,
    ),
  );

  getIt.registerFactory(() => GetSubscriptionStatusUseCase(getIt()));
  getIt.registerFactory(() => RestorePurchasesUseCase(getIt()));
  getIt.registerFactory(() => GetOfferingsUseCase(getIt()));
  getIt.registerFactory(() => PurchasePackageUseCase(getIt()));
  getIt.registerFactory(
    () => GetCurrentUsageUseCase(
      subscriptionRepository: getIt(),
      audioNotesRepository: getIt(),
    ),
  );

  getIt.registerLazySingleton(
    () => SubscriptionCubit(
      getSubscriptionStatus: getIt(),
      restorePurchases: getIt(),
      getOfferings: getIt(),
      purchasePackage: getIt(),
      repository: getIt(),
      getCurrentUsage: getIt(),
    ),
  );
}
