import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/thesis/domain/entities/weekly_thesis_export.dart';
import 'package:sample/features/thesis/domain/usecases/collect_week_usecase.dart';
import 'package:sample/features/thesis/domain/usecases/record_week_artifact_share_usecase.dart';

sealed class ThesisWeekExportState extends Equatable {
  const ThesisWeekExportState();

  @override
  List<Object?> get props => [];
}

class ThesisWeekExportInitial extends ThesisWeekExportState {
  const ThesisWeekExportInitial();
}

class ThesisWeekExportLoading extends ThesisWeekExportState {
  const ThesisWeekExportLoading();
}

/// No customer-discovery notes in the last 7 days — nothing honest to send.
class ThesisWeekExportEmpty extends ThesisWeekExportState {
  const ThesisWeekExportEmpty();
}

class ThesisWeekExportReady extends ThesisWeekExportState {
  const ThesisWeekExportReady(this.export);

  final WeeklyThesisExport export;

  @override
  List<Object?> get props => [export];
}

class ThesisWeekExportError extends ThesisWeekExportState {
  const ThesisWeekExportError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Loads the 7-day corpus for the Home “collect the week” sheet.
class ThesisWeekExportCubit extends Cubit<ThesisWeekExportState> {
  ThesisWeekExportCubit({
    required CollectWeekUseCase collectWeek,
    required RecordWeekArtifactShareUseCase recordWeekArtifactShare,
  }) : _collectWeek = collectWeek,
       _recordWeekArtifactShare = recordWeekArtifactShare,
       super(const ThesisWeekExportInitial());

  final CollectWeekUseCase _collectWeek;
  final RecordWeekArtifactShareUseCase _recordWeekArtifactShare;

  Future<void> load() async {
    emit(const ThesisWeekExportLoading());
    final result = await _collectWeek(const NoParams());
    if (isClosed) return;
    result.fold((failure) => emit(ThesisWeekExportError(failure)), (export) {
      if (!export.hasDebriefs) {
        emit(const ThesisWeekExportEmpty());
        return;
      }
      emit(ThesisWeekExportReady(export));
    });
  }

  /// Persist that the letter left via the OS share sheet. Copy must not
  /// call this. Failures stay off the sheet so a sent letter is not
  /// replaced by an error.
  Future<void> recordShare() async {
    if (state is! ThesisWeekExportReady) return;
    await _recordWeekArtifactShare(const NoParams());
  }
}
