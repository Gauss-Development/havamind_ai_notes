import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sample/core/constants/audio_notes_constants.dart';
import 'package:sample/features/audio_notes/data/services/audio_recording_service.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';
import 'package:sample/features/subscription/domain/usecases/get_current_usage_usecase.dart';
import 'package:sample/core/usecases/usecase.dart';

class PlanRefinementState extends Equatable {
  const PlanRefinementState._({
    this.status = PlanRefinementStatus.idle,
    this.elapsedSeconds = 0,
    this.isPaused = false,
    this.filePath,
    this.result,
    this.error,
    this.noteId,
    this.followUpQuestionId,
    this.followUpQuestionText,
  });

  const PlanRefinementState.idle() : this._(status: PlanRefinementStatus.idle);

  final PlanRefinementStatus status;
  final int elapsedSeconds;
  final bool isPaused;
  final String? filePath;
  final Map<String, dynamic>? result;
  final String? error;
  final String? noteId;
  final String? followUpQuestionId;
  final String? followUpQuestionText;

  PlanRefinementState copyWith({
    PlanRefinementStatus? status,
    int? elapsedSeconds,
    bool? isPaused,
    String? filePath,
    Map<String, dynamic>? result,
    String? error,
    String? noteId,
    String? followUpQuestionId,
    String? followUpQuestionText,
  }) {
    return PlanRefinementState._(
      status: status ?? this.status,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
      filePath: filePath ?? this.filePath,
      result: result ?? this.result,
      error: error,
      noteId: noteId ?? this.noteId,
      followUpQuestionId: followUpQuestionId ?? this.followUpQuestionId,
      followUpQuestionText: followUpQuestionText ?? this.followUpQuestionText,
    );
  }

  @override
  List<Object?> get props => [
    status,
    elapsedSeconds,
    isPaused,
    filePath,
    result,
    error,
    noteId,
    followUpQuestionId,
    followUpQuestionText,
  ];
}

enum PlanRefinementStatus {
  idle,
  recording,
  readyToSave,
  uploading,
  refining,
  success,
  failure,
  limitReached,
}

class PlanRefinementCubit extends Cubit<PlanRefinementState> {
  PlanRefinementCubit({
    required AudioRecordingService recordingService,
    required AudioNotesRepository repository,
    required GetCurrentUsageUseCase getCurrentUsage,
  }) : _recording = recordingService,
       _repository = repository,
       _getCurrentUsage = getCurrentUsage,
       super(const PlanRefinementState.idle());

  final AudioRecordingService _recording;
  final AudioNotesRepository _repository;
  final GetCurrentUsageUseCase _getCurrentUsage;
  Timer? _timer;
  int _effectiveMaxSeconds = kMaxRecordingDurationSeconds;

  void configure({
    required String noteId,
    String? followUpQuestionId,
    String? followUpQuestionText,
  }) {
    emit(
      state.copyWith(
        noteId: noteId,
        followUpQuestionId: followUpQuestionId,
        followUpQuestionText: followUpQuestionText,
      ),
    );
  }

  Future<void> startRecording() async {
    final usageResult = await _getCurrentUsage(const NoParams());
    final usageInfo = usageResult.fold((_) => null, (info) => info);
    if (usageInfo != null && usageInfo.isExhausted) {
      emit(state.copyWith(status: PlanRefinementStatus.limitReached));
      return;
    }

    _effectiveMaxSeconds = math.min(
      kMaxRecordingDurationSeconds,
      usageInfo?.remainingSeconds ?? kMaxRecordingDurationSeconds,
    );

    var micStatus = await Permission.microphone.status;
    if (micStatus.isDenied) {
      micStatus = await Permission.microphone.request();
    }
    if (!micStatus.isGranted) {
      final msg = micStatus.isPermanentlyDenied
          ? 'Microphone access is disabled. Enable it in Settings.'
          : 'Microphone access denied';
      emit(state.copyWith(status: PlanRefinementStatus.failure, error: msg));
      if (micStatus.isPermanentlyDenied) await openAppSettings();
      return;
    }

    final path = await _recording.createRecordingPath();
    try {
      await _recording.startRecording(path);
    } catch (e) {
      emit(
        state.copyWith(
          status: PlanRefinementStatus.failure,
          error: e.toString(),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: PlanRefinementStatus.recording,
        elapsedSeconds: 0,
        isPaused: false,
        filePath: path,
      ),
    );
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (state.status != PlanRefinementStatus.recording || state.isPaused) {
      return;
    }
    final next = state.elapsedSeconds + 1;
    if (next >= _effectiveMaxSeconds) {
      stopRecording();
    } else {
      emit(state.copyWith(elapsedSeconds: next));
    }
  }

  Future<void> pauseRecording() async {
    if (state.status != PlanRefinementStatus.recording || state.isPaused) {
      return;
    }
    _timer?.cancel();
    try {
      await _recording.pauseRecording();
    } catch (e) {
      emit(
        state.copyWith(
          status: PlanRefinementStatus.failure,
          error: e.toString(),
        ),
      );
      return;
    }
    emit(state.copyWith(isPaused: true));
  }

  Future<void> resumeRecording() async {
    if (state.status != PlanRefinementStatus.recording || !state.isPaused) {
      return;
    }
    try {
      await _recording.resumeRecording();
    } catch (e) {
      emit(
        state.copyWith(
          status: PlanRefinementStatus.failure,
          error: e.toString(),
        ),
      );
      return;
    }
    emit(state.copyWith(isPaused: false));
    _startTimer();
  }

  Future<void> stopRecording() async {
    _timer?.cancel();
    if (state.status != PlanRefinementStatus.recording) return;
    try {
      await _recording.stopRecording();
    } catch (e) {
      emit(
        state.copyWith(
          status: PlanRefinementStatus.failure,
          error: e.toString(),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: PlanRefinementStatus.readyToSave,
        isPaused: false,
        elapsedSeconds: state.elapsedSeconds == 0 ? 1 : state.elapsedSeconds,
      ),
    );
  }

  Future<void> cancelRecording() async {
    _timer?.cancel();
    if (state.filePath != null) {
      try {
        await _recording.cancelRecording();
        final f = File(state.filePath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    emit(const PlanRefinementState.idle());
  }

  Future<void> submitRecording() async {
    if (state.status != PlanRefinementStatus.readyToSave) return;
    final noteId = state.noteId;
    final filePath = state.filePath;
    if (noteId == null || filePath == null) return;

    // Enforce the per-plan refinement-round cap on the client. The server
    // is authoritative — `refine-plan` re-checks `MAX_REFINEMENT_ROUNDS`
    // against `plan_versions.plan_id = startup_analyses.id`. The client
    // mirrors that count via `audio_note_id`, which is set on the same
    // rows (and indexed by `plan_versions_audio_note_idx`). Using the
    // `analysis.id` key here would require fetching the analysis first;
    // the audio_note_id index gives us the exact same count in one hop.
    final countResult = await _repository.countRefinementRoundsForNote(noteId);
    final currentRounds = countResult.fold((_) => 0, (count) => count);
    if (currentRounds >= kMaxRefinementRounds) {
      emit(
        state.copyWith(
          status: PlanRefinementStatus.failure,
          error:
              'Maximum of $kMaxRefinementRounds refinement rounds reached for this plan.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: PlanRefinementStatus.refining));

    final result = await _repository.refinePlanByVoice(
      noteId: noteId,
      localFilePath: filePath,
      followUpQuestionId: state.followUpQuestionId,
      followUpQuestionText: state.followUpQuestionText,
    );

    result.fold(
      (f) => emit(
        state.copyWith(status: PlanRefinementStatus.failure, error: f.message),
      ),
      (data) => emit(
        state.copyWith(status: PlanRefinementStatus.success, result: data),
      ),
    );
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    // Don't dispose the recorder — it's shared across consumers (see DI).
    // Just cancel any in-flight recording so the mic is released cleanly.
    if (state.status == PlanRefinementStatus.recording) {
      try {
        await _recording.cancelRecording();
        final path = state.filePath;
        if (path != null) {
          final f = File(path);
          if (await f.exists()) await f.delete();
        }
      } catch (_) {}
    }
    return super.close();
  }
}
