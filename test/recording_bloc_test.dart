import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/data/services/audio_recording_service.dart';
import 'package:sample/features/audio_notes/domain/usecases/process_local_audio_note_usecase.dart';
import 'package:sample/features/audio_notes/presentation/bloc/recording_bloc.dart';
import 'package:sample/features/subscription/domain/entities/subscription_status.dart';
import 'package:sample/features/subscription/domain/entities/usage_info.dart';
import 'package:sample/features/subscription/domain/usecases/get_current_usage_usecase.dart';

class _MockRecordingService extends Mock implements AudioRecordingService {}

class _MockGetCurrentUsage extends Mock implements GetCurrentUsageUseCase {}

class _MockProcessLocalAudioNote extends Mock
    implements ProcessLocalAudioNoteUseCase {}

void main() {
  late _MockRecordingService recording;
  late _MockGetCurrentUsage getCurrentUsage;
  late _MockProcessLocalAudioNote processLocalAudioNote;

  const path = '/tmp/test_recording.m4a';

  final usage = UsageInfo(
    usedSeconds: 0,
    limitSeconds: 300,
    tier: SubscriptionTier.free,
    periodStart: DateTime.utc(2026),
    periodEnd: DateTime.utc(2026, 2),
  );

  // permission_handler talks to this channel; grant microphone in tests.
  const permissionsChannel = MethodChannel(
    'flutter.baseflow.com/permissions/methods',
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    recording = _MockRecordingService();
    getCurrentUsage = _MockGetCurrentUsage();
    processLocalAudioNote = _MockProcessLocalAudioNote();

    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionsChannel, (call) async {
      // microphone == 7; PermissionStatus.granted == 1.
      if (call.method == 'checkPermissionStatus') return 1;
      if (call.method == 'requestPermissions') return <int, int>{7: 1};
      return null;
    });

    when(() => getCurrentUsage(any())).thenAnswer((_) async => Right(usage));
    when(() => recording.createRecordingPath()).thenAnswer((_) async => path);
    when(() => recording.startRecording(any())).thenAnswer((_) async {});
    when(() => recording.pauseRecording()).thenAnswer((_) async {});
    when(() => recording.resumeRecording()).thenAnswer((_) async {});
    when(() => recording.stopRecording()).thenAnswer((_) async {});
    when(() => recording.cancelRecording()).thenAnswer((_) async {});
    when(() => recording.isRecording()).thenAnswer((_) async => false);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionsChannel, null);
  });

  RecordingBloc buildBloc() => RecordingBloc(
        recordingService: recording,
        processLocalAudioNote: processLocalAudioNote,
        getCurrentUsage: getCurrentUsage,
      );

  test('start enters recording (not paused)', () async {
    final bloc = buildBloc();
    bloc.add(const RecordingEvent.startPressed());
    await expectLater(
      bloc.stream,
      emits(
        const RecordingState.recording(
          elapsedSeconds: 0,
          filePath: path,
          isPaused: false,
        ),
      ),
    );
    await bloc.close();
  });

  test('pause then resume keeps the same take and freezes the timer', () async {
    final bloc = buildBloc();
    bloc.add(const RecordingEvent.startPressed());
    await bloc.stream.firstWhere(
      (s) => s.maybeWhen(
        recording: (_, _, isPaused) => !isPaused,
        orElse: () => false,
      ),
    );

    // Advance one tick so we have a non-zero elapsed time to assert on.
    bloc.add(const RecordingEvent.tick());
    await bloc.stream.firstWhere(
      (s) => s.maybeWhen(
        recording: (elapsed, _, _) => elapsed == 1,
        orElse: () => false,
      ),
    );

    bloc.add(const RecordingEvent.pausePressed());
    await expectLater(
      bloc.stream,
      emits(
        const RecordingState.recording(
          elapsedSeconds: 1,
          filePath: path,
          isPaused: true,
        ),
      ),
    );

    // A stray tick while paused must NOT advance the counter.
    bloc.add(const RecordingEvent.tick());
    bloc.add(const RecordingEvent.resumePressed());
    await expectLater(
      bloc.stream,
      emits(
        const RecordingState.recording(
          elapsedSeconds: 1,
          filePath: path,
          isPaused: false,
        ),
      ),
    );

    verify(() => recording.pauseRecording()).called(1);
    verify(() => recording.resumeRecording()).called(1);
    await bloc.close();
  });

  test('done from paused finalizes into readyToSave', () async {
    final bloc = buildBloc();
    bloc.add(const RecordingEvent.startPressed());
    await bloc.stream.firstWhere(
      (s) => s.maybeWhen(
        recording: (_, _, isPaused) => !isPaused,
        orElse: () => false,
      ),
    );

    bloc.add(const RecordingEvent.tick());
    bloc.add(const RecordingEvent.pausePressed());
    await bloc.stream.firstWhere(
      (s) => s.maybeWhen(
        recording: (_, _, isPaused) => isPaused,
        orElse: () => false,
      ),
    );

    bloc.add(const RecordingEvent.stopPressed());
    await expectLater(
      bloc.stream,
      emits(
        const RecordingState.readyToSave(filePath: path, durationSeconds: 1),
      ),
    );

    verify(() => recording.stopRecording()).called(1);
    await bloc.close();
  });
}
