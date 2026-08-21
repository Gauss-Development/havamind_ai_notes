import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/features/audio_notes/domain/entities/plan_version.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class PlanVersionHistoryState extends Equatable {
  const PlanVersionHistoryState({
    this.versions = const [],
    this.isLoading = false,
    this.isRestoring = false,
    this.restoredRound,
    this.error,
  });

  final List<PlanVersion> versions;
  final bool isLoading;
  final bool isRestoring;
  final int? restoredRound;
  final String? error;

  PlanVersionHistoryState copyWith({
    List<PlanVersion>? versions,
    bool? isLoading,
    bool? isRestoring,
    int? restoredRound,
    String? error,
  }) {
    return PlanVersionHistoryState(
      versions: versions ?? this.versions,
      isLoading: isLoading ?? this.isLoading,
      isRestoring: isRestoring ?? this.isRestoring,
      restoredRound: restoredRound,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    versions,
    isLoading,
    isRestoring,
    restoredRound,
    error,
  ];
}

class PlanVersionHistoryCubit extends Cubit<PlanVersionHistoryState> {
  PlanVersionHistoryCubit({required AudioNotesRepository repository})
    : _repository = repository,
      super(const PlanVersionHistoryState());

  final AudioNotesRepository _repository;

  Future<void> load(String planId) async {
    emit(state.copyWith(isLoading: true));
    final result = await _repository.listPlanVersions(planId);
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (versions) => emit(state.copyWith(versions: versions, isLoading: false)),
    );
  }

  Future<void> restore(String versionId) async {
    emit(state.copyWith(isRestoring: true));
    final result = await _repository.restorePlanVersion(versionId);
    result.fold(
      (f) => emit(state.copyWith(isRestoring: false, error: f.message)),
      (data) {
        final restoredFrom = data['restoredFrom'] as int?;
        emit(state.copyWith(isRestoring: false, restoredRound: restoredFrom));
      },
    );
  }
}
