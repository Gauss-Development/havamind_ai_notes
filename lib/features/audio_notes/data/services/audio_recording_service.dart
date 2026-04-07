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
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
  }

  Future<bool> isRecording() => _recorder.isRecording();

  Future<void> dispose() => _recorder.dispose();
}
