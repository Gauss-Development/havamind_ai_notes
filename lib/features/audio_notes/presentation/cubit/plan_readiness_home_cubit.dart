import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/usecases/get_note_analysis_usecase.dart';
import 'package:sample/features/audio_notes/domain/utils/analysis_plan_gaps.dart';

/// Home-screen nudge pointing at the least-complete analyzed note.
class PlanReadinessNudge extends Equatable {
  const PlanReadinessNudge({
    required this.noteId,
    required this.noteTitle,
    required this.readiness,
  });

  final String noteId;
  final String noteTitle;
  final PlanReadiness readiness;

  @override
  List<Object?> get props => [noteId, noteTitle, readiness];
}

class PlanReadinessHomeCubit extends Cubit<PlanReadinessNudge?> {
  PlanReadinessHomeCubit({required GetNoteAnalysisUseCase getAnalysis})
    : _getAnalysis = getAnalysis,
      super(null);

  static const _scanLimit = 5;

  final GetNoteAnalysisUseCase _getAnalysis;

  Future<void> refreshFromNotes(List<AudioNote> notes) async {
    final completed =
        notes.where((note) => note.status == AudioNoteStatus.completed).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (completed.isEmpty) {
      if (!isClosed) emit(null);
      return;
    }

    PlanReadinessNudge? weakest;

    for (final note in completed.take(_scanLimit)) {
      final result = await _getAnalysis(note.id);
      if (isClosed) return;

      final analysis = result.fold((_) => null, (value) => value);
      if (analysis == null) continue;

      final readiness = computePlanReadiness(analysis);
      if (readiness.isComplete) continue;

      final noteTitle = note.title.trim();
      final analysisTitle = analysis.startupTitle?.trim() ?? '';
      final title = noteTitle.isNotEmpty ? noteTitle : analysisTitle;

      if (weakest == null ||
          readiness.percent < weakest.readiness.percent ||
          (readiness.percent == weakest.readiness.percent &&
              readiness.gapCount > weakest.readiness.gapCount)) {
        weakest = PlanReadinessNudge(
          noteId: note.id,
          noteTitle: title,
          readiness: readiness,
        );
      }
    }

    if (!isClosed) emit(weakest);
  }
}
