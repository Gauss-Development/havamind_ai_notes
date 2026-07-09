import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Wraps [AudioRecorder] for recording sessions (no domain logic).
class AudioRecordingService {
  AudioRecordingService() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;

  Future<bool> hasPermission({bool request = true}) {
    return _recorder.hasPermission(request: request);
  }

  /// Creates a recording file path inside the persistent app documents
  /// directory so that files survive across app restarts and OS cache purges.
  Future<String> createRecordingPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${dir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    final name = '${_uuid.v4()}.m4a';
    return '${recordingsDir.path}/$name';
  }

  Future<void> startRecording(String path) async {
    // Singleton-recorder guard: if another consumer (e.g. RecordingPage
    // and a parallel RefinementRecordingPage from a double-tap) is still
    // recording, the second `start` would either throw deep inside the
    // platform plugin or silently overwrite the active file. Fail fast
    // here with a user-facing message instead.
    if (await _recorder.isRecording()) {
      throw StateError(
        'Microphone is already in use by another recording. '
        'Finish or cancel that recording before starting a new one.',
      );
    }
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
  }

  /// Pauses the active recording. The session and the underlying file stay
  /// open so [resumeRecording] appends to the same take.
  Future<void> pauseRecording() async {
    await _recorder.pause();
  }

  /// Resumes a previously paused recording into the same file.
  Future<void> resumeRecording() async {
    await _recorder.resume();
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
  }

  Future<bool> isRecording() => _recorder.isRecording();

  Future<bool> isPaused() => _recorder.isPaused();

  Future<void> dispose() => _recorder.dispose();
}
