import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sample/features/tags/domain/entities/note_tag.dart';

const _uuid = Uuid();

class TagsRemoteDataSource {
  TagsRemoteDataSource(this._client);

  final SupabaseClient _client;

  String get _userId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    return uid;
  }

  Future<List<NoteTag>> listTags() async {
    final rows = await _client
        .from('tags')
        .select()
        .eq('user_id', _userId)
        .order('name');

    return (rows as List<dynamic>)
        .map((e) => _tagFromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<NoteTag> createTag(String name) async {
    final id = _uuid.v4();
    final row = await _client
        .from('tags')
        .insert({
          'id': id,
          'user_id': _userId,
          'name': name.trim(),
        })
        .select()
        .single();
    return _tagFromRow(Map<String, dynamic>.from(row));
  }

  Future<void> deleteTag(String tagId) async {
    await _client.from('tags').delete().eq('id', tagId);
  }

  Future<List<String>> getTagIdsForNote(String noteId) async {
    final rows = await _client
        .from('note_tags')
        .select('tag_id')
        .eq('audio_note_id', noteId);

    return (rows as List<dynamic>)
        .map((e) => (e as Map)['tag_id'] as String)
        .toList();
  }

  Future<void> setTagsForNote(String noteId, List<String> tagIds) async {
    await _client
        .from('note_tags')
        .delete()
        .eq('audio_note_id', noteId);

    if (tagIds.isEmpty) return;

    final insertRows = tagIds
        .map((tid) => {
              'audio_note_id': noteId,
              'tag_id': tid,
              'user_id': _userId,
            })
        .toList();

    await _client.from('note_tags').insert(insertRows);
  }

  NoteTag _tagFromRow(Map<String, dynamic> row) {
    return NoteTag(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
