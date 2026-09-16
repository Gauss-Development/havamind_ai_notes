import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/usecases/get_thesis_usecase.dart';
import 'package:sample/features/thesis/domain/usecases/seed_thesis_usecase.dart';
import 'package:sample/features/thesis/domain/utils/thesis_readiness.dart';

sealed class ThesisHomeState extends Equatable {
  const ThesisHomeState();

  @override
  List<Object?> get props => [];
}

class ThesisHomeInitial extends ThesisHomeState {
  const ThesisHomeInitial();
}

class ThesisHomeLoading extends ThesisHomeState {
  const ThesisHomeLoading();
}

class ThesisHomeLoaded extends ThesisHomeState {
  const ThesisHomeLoaded({
    required this.thesis,
    required this.readiness,
    required this.unbackedGaps,
  });

  factory ThesisHomeLoaded.fromThesis(Thesis thesis) {
    final readiness = computeThesisReadiness(thesis);
    return ThesisHomeLoaded(
      thesis: thesis,
      readiness: readiness,
      unbackedGaps: selectThesisUnbackedGaps(thesis),
    );
  }

  final Thesis thesis;
  final ThesisReadiness readiness;
  final List<ThesisUnbackedGap> unbackedGaps;

  bool get isBlank => readiness.isBlankThesis(thesis);

  @override
  List<Object?> get props => [thesis, readiness, unbackedGaps];
}

class ThesisHomeError extends ThesisHomeState {
  const ThesisHomeError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Seeds the account thesis on first Home open, then exposes readiness.
class ThesisHomeCubit extends Cubit<ThesisHomeState> {
  ThesisHomeCubit({
    required SeedThesisUseCase seedThesis,
    required GetThesisUseCase getThesis,
  }) : _seedThesis = seedThesis,
       _getThesis = getThesis,
       super(const ThesisHomeInitial());

  final SeedThesisUseCase _seedThesis;
  final GetThesisUseCase _getThesis;

  /// First open: create or attach the thesis if the account has none.
  Future<void> load() async {
    emit(const ThesisHomeLoading());
    final result = await _seedThesis(const NoParams());
    if (isClosed) return;
    result.fold(
      (failure) => emit(ThesisHomeError(failure)),
      (thesis) => emit(ThesisHomeLoaded.fromThesis(thesis)),
    );
  }

  /// Re-read after a debrief or pull-to-refresh. Seeds again if the row vanished.
  Future<void> refresh() async {
    if (state is ThesisHomeLoading) return;
    final result = await _getThesis(const NoParams());
    if (isClosed) return;
    await result.fold<Future<void>>(
      (failure) async => emit(ThesisHomeError(failure)),
      (thesis) async {
        if (thesis == null) {
          await load();
          return;
        }
        emit(ThesisHomeLoaded.fromThesis(thesis));
      },
    );
  }
}
