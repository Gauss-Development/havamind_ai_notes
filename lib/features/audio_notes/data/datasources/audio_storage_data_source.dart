import 'dart:io';

import 'package:sample/core/constants/audio_notes_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AudioStorageDataSource {
  AudioStorageDataSource(this._client);

  final SupabaseClient _client;

  Future<void> uploadObject({
    required String objectPath,
    required File file,
  }) async {
    await _client.storage
        .from(kAudioNotesBucketId)
        .upload(
          objectPath,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'audio/m4a',
          ),
        );
  }

  Future<void> removeObject(String objectPath) async {
    await _client.storage.from(kAudioNotesBucketId).remove([objectPath]);
  }
}
