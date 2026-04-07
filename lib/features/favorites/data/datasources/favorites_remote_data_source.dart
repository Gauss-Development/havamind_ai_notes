import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sample/features/audio_notes/data/models/audio_note_mapper.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';

class FavoritesRemoteDataSource {
  FavoritesRemoteDataSource(this._client);

  final SupabaseClient _client;

  String get _userId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    return uid;
  }

  Future<List<AudioNote>> listFavoriteNotes() async {
    final rows = await _client
        .from('favorites')
        .select('audio_note_id, audio_notes!inner(*)')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>).map((e) {
      final noteRow = Map<String, dynamic>.from(
        (e as Map)['audio_notes'] as Map,
      );
      return AudioNoteMapper.fromRow(noteRow);
    }).toList();
  }

  Future<Set<String>> getFavoriteNoteIds() async {
    final rows = await _client
        .from('favorites')
        .select('audio_note_id')
        .eq('user_id', _userId);

    return (rows as List<dynamic>)
        .map((e) => (e as Map)['audio_note_id'] as String)
        .toSet();
  }

  Future<bool> isFavorite(String noteId) async {
    final rows = await _client
        .from('favorites')
        .select('id')
        .eq('user_id', _userId)
        .eq('audio_note_id', noteId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> addFavorite(String noteId) async {
    await _client.from('favorites').insert({
      'user_id': _userId,
      'audio_note_id': noteId,
    });
  }

  Future<void> removeFavorite(String noteId) async {
    await _client
        .from('favorites')
        .delete()
        .eq('user_id', _userId)
        .eq('audio_note_id', noteId);
  }
}
