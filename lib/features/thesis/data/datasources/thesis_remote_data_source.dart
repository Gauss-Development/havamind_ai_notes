import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:sample/features/audio_notes/data/models/startup_analysis_mapper.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/thesis/data/models/thesis_mapper.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_seed_candidate.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';

const _uuid = Uuid();

class ThesisRemoteDataSource {
  ThesisRemoteDataSource(this._client);

  final SupabaseClient _client;

  String get _userId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('Not signed in');
    }
    return uid;
  }

  Future<Thesis?> fetchCurrent() async {
    final row = await _client
        .from('theses')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();
    if (row == null) return null;
    return ThesisMapper.fromRow(Map<String, dynamic>.from(row));
  }

  Future<List<ThesisSeedCandidate>> listSeedCandidates() async {
    final userId = _userId;
    final analysisRows = await _client
        .from('startup_analyses')
        .select()
        .eq('user_id', userId);
    final noteRows = await _client
        .from('audio_notes')
        .select('id, created_at')
        .eq('user_id', userId)
        .eq('status', AudioNoteStatus.completed.dbValue);

    final noteCreatedAt = <String, DateTime>{};
    for (final raw in noteRows as List<dynamic>) {
      final row = Map<String, dynamic>.from(raw as Map);
      noteCreatedAt[row['id'] as String] = DateTime.parse(
        row['created_at'] as String,
      );
    }

    final candidates = <ThesisSeedCandidate>[];
    for (final raw in analysisRows as List<dynamic>) {
      final row = Map<String, dynamic>.from(raw as Map);
      final noteId = row['audio_note_id'] as String;
      final createdAt = noteCreatedAt[noteId];
      if (createdAt == null) continue;
      candidates.add(
        ThesisSeedCandidate(
          analysis: StartupAnalysisMapper.fromRow(row),
          noteCreatedAt: createdAt,
        ),
      );
    }
    return candidates;
  }

  Future<Thesis> insertThesis(ThesisDraft draft) async {
    final payload = <String, dynamic>{
      'id': _uuid.v4(),
      'user_id': _userId,
      ...ThesisMapper.draftToInsert(draft),
    };

    try {
      final row = await _client
          .from('theses')
          .insert(payload)
          .select()
          .single();
      return ThesisMapper.fromRow(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      // Concurrent seed: unique(user_id) lost the race — return the winner.
      if (e.code == '23505') {
        final existing = await fetchCurrent();
        if (existing != null) return existing;
      }
      rethrow;
    }
  }

  Future<void> attachThesisToAllNotes(String thesisId) async {
    await _client
        .from('audio_notes')
        .update({'thesis_id': thesisId})
        .eq('user_id', _userId);
  }

  Future<List<ThesisVersion>> fetchRecentVersions({int limit = 2}) async {
    final rows = await _client
        .from('thesis_versions')
        .select()
        .eq('user_id', _userId)
        .order('round_number', ascending: false)
        .limit(limit);
    return [
      for (final raw in rows as List<dynamic>)
        ThesisMapper.versionFromRow(Map<String, dynamic>.from(raw as Map)),
    ];
  }
}
