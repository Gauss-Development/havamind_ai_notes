import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sample/core/constants/audio_notes_constants.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/data/services/audio_recording_service.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/usecases/process_local_audio_note_usecase.dart';
import 'package:sample/features/subscription/domain/usecases/get_current_usage_usecase.dart';

part 'recording_bloc.freezed.dart';

@freezed
class RecordingEvent with _$RecordingEvent {
  const factory RecordingEvent.startPressed() = _StartPressed;
  const factory RecordingEvent.stopPressed() = _StopPressed;
  const factory RecordingEvent.cancelPressed() = _CancelPressed;
  const factory RecordingEvent.savePressed() = _SavePressed;
  const factory RecordingEvent.tick() = _Tick;
}

@freezed
class RecordingState with _$RecordingState {
  const factory RecordingState.idle() = _Idle;
  const factory RecordingState.recording({
    required int elapsedSeconds,
    required String filePath,
  }) = _Recording;
  const factory RecordingState.readyToSave({
    required String filePath,
    required int durationSeconds,
  }) = _ReadyToSave;
  const factory RecordingState.uploading() = _Uploading;
  const factory RecordingState.success(AudioNote note) = _Success;
  const factory RecordingState.failure(String message) = _Failure;

  /// User attempted to record but their monthly quota is exhausted.
  /// Triggers the paywall sheet at the listening page.
  const factory RecordingState.limitReached() = _LimitReached;
}

class RecordingBloc extends Bloc<RecordingEvent, RecordingState> {
  RecordingBloc({
    required AudioRecordingService recordingService,
    required ProcessLocalAudioNoteUseCase processLocalAudioNote,
    required GetCurrentUsageUseCase getCurrentUsage,
  }) : _recording = recordingService,
       _processLocalAudioNote = processLocalAudioNote,
       _getCurrentUsage = getCurrentUsage,
       super(const RecordingState.idle()) {
    on<_StartPressed>(_onStart);
    on<_StopPressed>(_onStop);
    on<_CancelPressed>(_onCancel);
    on<_SavePressed>(_onSave);
    on<_Tick>(_onTick);
  }

  final AudioRecordingService _recording;
  final ProcessLocalAudioNoteUseCase _processLocalAudioNote;
  final GetCurrentUsageUseCase _getCurrentUsage;
  Timer? _timer;
  int _effectiveMaxSeconds = kMaxRecordingDurationSeconds;

  Future<void> _onStart(
    _StartPressed event,
    Emitter<RecordingState> emit,
  ) async {
    final usageResult = await _getCurrentUsage(const NoParams());
    final usageInfo = usageResult.fold((_) => null, (info) => info);
    if (usageInfo != null && usageInfo.isExhausted) {
      emit(const RecordingState.limitReached());
      emit(const RecordingState.idle());
      return;
    }

    _effectiveMaxSeconds = math.min(
      kMaxRecordingDurationSeconds,
      usageInfo?.remainingSeconds ?? kMaxRecordingDurationSeconds,
    );

    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    if (!status.isGranted) {
      final msg = status.isPermanentlyDenied
          ? 'Microphone access is disabled. Enable it in Settings → Audio Notes → Microphone.'
          : 'Microphone access denied';
      emit(RecordingState.failure(msg));
      emit(const RecordingState.idle());
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return;
    }

    final path = await _recording.createRecordingPath();
    try {
      await _recording.startRecording(path);
    } catch (e) {
      emit(RecordingState.failure(e.toString()));
      emit(const RecordingState.idle());
      return;
    }

    emit(RecordingState.recording(elapsedSeconds: 0, filePath: path));
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const RecordingEvent.tick()),
    );
  }

  Future<void> _onTick(_Tick event, Emitter<RecordingState> emit) async {
    await state.maybeWhen(
      recording: (elapsedSeconds, filePath) async {
        final next = elapsedSeconds + 1;
        if (next >= _effectiveMaxSeconds) {
          _timer?.cancel();
          await _finalizeStop(emit, filePath, _effectiveMaxSeconds);
        } else {
          emit(
            RecordingState.recording(elapsedSeconds: next, filePath: filePath),
          );
        }
      },
      orElse: () async {},
    );
  }

  Future<void> _onStop(_StopPressed event, Emitter<RecordingState> emit) async {
    await state.maybeWhen(
      recording: (elapsedSeconds, filePath) async {
        _timer?.cancel();
        await _finalizeStop(emit, filePath, elapsedSeconds);
      },
      orElse: () async {},
    );
  }

  Future<void> _finalizeStop(
    Emitter<RecordingState> emit,
    String path,
    int durationSeconds,
  ) async {
    try {
      await _recording.stopRecording();
    } catch (e) {
      emit(RecordingState.failure(e.toString()));
      emit(const RecordingState.idle());
      return;
    }
    emit(
      RecordingState.readyToSave(
        filePath: path,
        durationSeconds: durationSeconds == 0 ? 1 : durationSeconds,
      ),
    );
  }

  Future<void> _onCancel(
    _CancelPressed event,
    Emitter<RecordingState> emit,
  ) async {
    _timer?.cancel();
    await state.maybeWhen(
      recording: (elapsedSeconds, filePath) async {
        try {
          await _recording.cancelRecording();
          final f = File(filePath);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      },
      readyToSave: (filePath, durationSeconds) async {
        try {
          final f = File(filePath);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      },
      orElse: () async {},
    );
    emit(const RecordingState.idle());
  }

  Future<void> _onSave(_SavePressed event, Emitter<RecordingState> emit) async {
    await state.maybeWhen(
      readyToSave: (filePath, durationSeconds) async {
        emit(const RecordingState.uploading());
        final result = await _processLocalAudioNote(
          ProcessLocalAudioNoteParams(
            localFilePath: filePath,
            durationSeconds: durationSeconds,
          ),
        );
        result.fold((f) {
          emit(RecordingState.failure(f.message));
          emit(const RecordingState.idle());
        }, (note) => emit(RecordingState.success(note)));
      },
      orElse: () async {},
    );
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _recording.dispose();
    return super.close();
  }
}
