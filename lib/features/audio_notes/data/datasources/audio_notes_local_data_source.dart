import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';

const _kCachedNotesKey = 'cached_audio_notes';

/// Simple JSON-based local cache for the notes list.
///
/// Uses [SharedPreferences] to persist serialized notes between sessions.
/// This is intentionally lightweight — for a larger dataset, consider
/// a proper local DB like Drift or Isar.
class AudioNotesLocalDataSource {
  AudioNotesLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  Future<void> cacheNotes(List<AudioNote> notes) async {
    final jsonList = notes.map(_noteToJson).toList();
    await _prefs.setString(_kCachedNotesKey, jsonEncode(jsonList));
  }

  List<AudioNote>? getCachedNotes() {
    final raw = _prefs.getString(_kCachedNotesKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>().map(_noteFromJson).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCache() async {
    await _prefs.remove(_kCachedNotesKey);
  }

  Map<String, dynamic> _noteToJson(AudioNote note) => {
    'id': note.id,
    'userId': note.userId,
    'title': note.title,
    'audioPath': note.audioPath,
    'durationSeconds': note.durationSeconds,
    'status': note.status.name,
    'createdAt': note.createdAt.toIso8601String(),
    'updatedAt': note.updatedAt.toIso8601String(),
    'templateId': note.templateId,
    'lastProcessingError': note.lastProcessingError,
  };

  AudioNote _noteFromJson(Map<String, dynamic> json) => AudioNote(
    id: json['id'] as String,
    userId: json['userId'] as String,
    title: json['title'] as String,
    audioPath: json['audioPath'] as String?,
    durationSeconds: json['durationSeconds'] as int,
    status: AudioNoteStatus.values.firstWhere(
      (s) => s.name == json['status'],
      orElse: () => AudioNoteStatus.draft,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    templateId: RecordingTemplateIds.normalize(json['templateId'] as String?),
    lastProcessingError: json['lastProcessingError'] as String?,
  );
}
