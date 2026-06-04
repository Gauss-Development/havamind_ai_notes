import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:sample/core/constants/audio_notes_constants.dart';
import 'package:sample/features/audio_notes/domain/entities/plan_version.dart';
import 'package:sample/features/audio_notes/data/models/audio_note_mapper.dart';
import 'package:sample/features/audio_notes/data/models/audio_note_transcript_mapper.dart';
import 'package:sample/features/audio_notes/data/models/startup_analysis_mapper.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/note_search_hit.dart';
import 'package:sample/features/search/domain/utils/transcript_excerpt.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_transcript.dart';
import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';

class AudioNotesRemoteDataSource {
  AudioNotesRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<AudioNote>> listForCurrentUser({
    int limit = 20,
    int offset = 0,
    List<String>? tagIds,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not signed in');
    }

    if (tagIds != null && tagIds.isNotEmpty) {
      // Join through note_tags to filter by tags.
      // Fetch note IDs that have ALL of the selected tags, then load notes.
      final tagRows = await _client
          .from('note_tags')
          .select('audio_note_id')
          .eq('user_id', userId)
          .inFilter('tag_id', tagIds);

      // Count how many of the requested tags each note matches.
      final counts = <String, int>{};
      for (final row in tagRows as List<dynamic>) {
        final noteId = (row as Map)['audio_note_id'] as String;
        counts[noteId] = (counts[noteId] ?? 0) + 1;
      }
      // Keep notes matching at least one selected tag (OR filter).
      final matchingIds = counts.keys.toList();

      if (matchingIds.isEmpty) return [];

      final rows = await _client
          .from('audio_notes')
          .select()
          .eq('user_id', userId)
          .inFilter('id', matchingIds)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return (rows as List<dynamic>)
          .map(
            (e) =>
                AudioNoteMapper.fromRow(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    }

    final rows = await _client
        .from('audio_notes')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (rows as List<dynamic>)
        .map(
          (e) => AudioNoteMapper.fromRow(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  /// Server-side title search. Uses Postgres `ILIKE` with escaped wildcards.
  Future<List<AudioNote>> searchByTitle({
    required String query,
    int limit = 20,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not signed in');
    }
    final pattern = '%${_escapeIlike(query)}%';
    final rows = await _client
        .from('audio_notes')
        .select()
        .eq('user_id', userId)
        .ilike('title', pattern)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List<dynamic>)
        .map(
          (e) => AudioNoteMapper.fromRow(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  /// Full-text search across note titles and transcript bodies (RPC).
  Future<List<NoteSearchHit>> searchNotes({
    required String query,
    int limit = 20,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not signed in');
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final response = await _client.rpc(
      'search_audio_notes',
      params: {
        'p_query': trimmed,
        'p_limit': limit,
      },
    );

    return (response as List<dynamic>)
        .map(
          (e) => _mapSearchHit(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  NoteSearchHit _mapSearchHit(Map<String, dynamic> row) {
    final matchTypeRaw = row['match_type'] as String? ?? 'title';
    final matchType = matchTypeRaw == 'transcript'
        ? NoteSearchMatchType.transcript
        : NoteSearchMatchType.title;

    final excerptRaw = row['match_excerpt'] as String?;
    final excerpt = excerptRaw == null || excerptRaw.trim().isEmpty
        ? null
        : stripTsHeadlineHtml(excerptRaw);

    return NoteSearchHit(
      note: AudioNoteMapper.fromRow(row),
      matchType: matchType,
      excerpt: excerpt,
    );
  }

  /// Total count of notes for the current user (head-only request).
  Future<int> countForCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not signed in');
    }
    return _client
        .from('audio_notes')
        .count(CountOption.exact)
        .eq('user_id', userId);
  }

  String _escapeIlike(String input) =>
      input.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');

  Future<AudioNote> fetchById(String id) async {
    final row = await _client
        .from('audio_notes')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      throw Exception('Note not found');
    }
    return AudioNoteMapper.fromRow(Map<String, dynamic>.from(row));
  }

  Future<void> insertDraft({
    required String id,
    required String userId,
    required String title,
    required String audioPath,
    required int durationSeconds,
    required String templateId,
  }) async {
    await _client.from('audio_notes').insert({
      'id': id,
      'user_id': userId,
      'title': title,
      'audio_path': audioPath,
      'duration_seconds': durationSeconds,
      'template_id': templateId,
      'status': AudioNoteStatus.draft.dbValue,
    });
  }

  Future<void> upsertTranscript({
    required String audioNoteId,
    required String userId,
    required String transcriptText,
    String? language,
  }) async {
    await _client.from('audio_note_transcripts').upsert({
      'audio_note_id': audioNoteId,
      'user_id': userId,
      'transcript_text': transcriptText,
      'language': language,
    }, onConflict: 'audio_note_id');
  }

  Future<void> upsertAnalysis({
    required String audioNoteId,
    required String userId,
    String? shortSummary,
    String? startupTitle,
    String? problem,
    String? solution,
    String? targetAudience,
    String? businessModel,
    String? keyMetrics,
    String? advantages,
    String? risksGaps,
    List<String>? followUpQuestions,
    int? marketPotentialScore,
    int? technicalComplexityScore,
    required Map<String, dynamic> rawAiResponse,
  }) async {
    await _client.from('startup_analyses').upsert({
      'audio_note_id': audioNoteId,
      'user_id': userId,
      'short_summary': shortSummary,
      'startup_title': startupTitle,
      'problem': problem,
      'solution': solution,
      'target_audience': targetAudience,
      'business_model': businessModel,
      'key_metrics': keyMetrics,
      'advantages': advantages,
      'risks_gaps': risksGaps,
      'follow_up_questions': followUpQuestions,
      'market_potential_score': marketPotentialScore,
      'technical_complexity_score': technicalComplexityScore,
      'raw_ai_response': rawAiResponse,
    }, onConflict: 'audio_note_id');
  }

  Future<void> updateStatus(
    String id,
    AudioNoteStatus status, {
    String? lastProcessingError,
    bool clearLastProcessingError = false,
  }) async {
    final patch = <String, dynamic>{'status': status.dbValue};
    if (clearLastProcessingError) {
      patch['last_processing_error'] = null;
    } else if (lastProcessingError != null) {
      patch['last_processing_error'] = lastProcessingError;
    }
    try {
      await _client.from('audio_notes').update(patch).eq('id', id);
    } on PostgrestException catch (e) {
      // Backward compatibility: some environments do not have
      // `last_processing_error` yet. Retry without this column.
      if (_isMissingLastProcessingErrorColumnError(e) &&
          patch.containsKey('last_processing_error')) {
        final fallbackPatch = Map<String, dynamic>.from(patch)
          ..remove('last_processing_error');
        await _client.from('audio_notes').update(fallbackPatch).eq('id', id);
        return;
      }
      rethrow;
    }
  }

  bool _isMissingLastProcessingErrorColumnError(PostgrestException e) {
    final msg = e.message.toLowerCase();
    final details = e.details?.toString().toLowerCase() ?? '';
    return e.code == 'PGRST204' &&
        (msg.contains('last_processing_error') ||
            details.contains('last_processing_error'));
  }

  Future<void> updateAudioPath(String id, String audioPath) async {
    await _client
        .from('audio_notes')
        .update({'audio_path': audioPath})
        .eq('id', id);
  }

  Future<void> deleteRow(String id) async {
    await _client.from('audio_notes').delete().eq('id', id);
  }

  /// Invokes Edge Function. Non-2xx responses throw [FunctionException] (not a return value).
  Future<void> invokeProcessing(String noteId) async {
    try {
      final res = await _client.functions.invoke(
        kProcessAudioNoteEdgeFunction,
        body: {'audio_note_id': noteId},
      );
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
    } on FunctionException catch (e) {
      throw Exception(_messageFromFunctionException(e));
    }
  }

  String _messageFromFunctionException(FunctionException e) {
    final d = e.details;
    if (d is Map) {
      final err = d['error'];
      if (err != null) return err.toString();
      final msg = d['message'];
      if (msg != null) return msg.toString();
    }
    if (d is String && d.isNotEmpty) return d;
    return 'Edge Function error (HTTP ${e.status})';
  }

  Future<AudioNoteTranscript?> fetchTranscript(String noteId) async {
    final row = await _client
        .from('audio_note_transcripts')
        .select()
        .eq('audio_note_id', noteId)
        .maybeSingle();
    if (row == null) return null;
    return AudioNoteTranscriptMapper.fromRow(Map<String, dynamic>.from(row));
  }

  Future<StartupAnalysis?> fetchAnalysis(String noteId) async {
    final row = await _client
        .from('startup_analyses')
        .select()
        .eq('audio_note_id', noteId)
        .maybeSingle();
    if (row == null) return null;
    return StartupAnalysisMapper.fromRow(Map<String, dynamic>.from(row));
  }

  Future<void> updateAnalysisField({
    required String noteId,
    required StartupAnalysisEditableField field,
    required String value,
  }) async {
    final column = switch (field) {
      StartupAnalysisEditableField.problem => 'problem',
      StartupAnalysisEditableField.solution => 'solution',
      StartupAnalysisEditableField.targetAudience => 'target_audience',
      StartupAnalysisEditableField.businessModel => 'business_model',
      StartupAnalysisEditableField.keyMetrics => 'key_metrics',
      StartupAnalysisEditableField.advantages => 'advantages',
      StartupAnalysisEditableField.risksGaps => 'risks_gaps',
      StartupAnalysisEditableField.shortSummary => 'short_summary',
      StartupAnalysisEditableField.startupTitle => 'startup_title',
    };
    await _client
        .from('startup_analyses')
        .update({column: value})
        .eq('audio_note_id', noteId);
  }

  Future<void> updateTitle(String id, String title) async {
    await _client.from('audio_notes').update({'title': title}).eq('id', id);
  }

  Future<int> getTotalUsageSeconds({
    required DateTime from,
    required DateTime to,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not signed in');
    }
    final rows = await _client
        .from('audio_notes')
        .select('duration_seconds')
        .eq('user_id', userId)
        .neq('status', AudioNoteStatus.failed.dbValue)
        .gte('created_at', from.toUtc().toIso8601String())
        .lt('created_at', to.toUtc().toIso8601String());
    final list = rows as List<dynamic>;
    var total = 0;
    for (final row in list) {
      total += ((row as Map)['duration_seconds'] as num).toInt();
    }
    return total;
  }

  /// Counts how many refinement rounds exist for an `audio_notes.id`.
  /// Uses the `plan_versions_audio_note_idx` index and a HEAD-only count
  /// so the payload is a single number, not the full version list.
  Future<int> countRefinementRoundsForNote(String audioNoteId) async {
    return _client
        .from('plan_versions')
        .count(CountOption.exact)
        .eq('audio_note_id', audioNoteId);
  }

  Future<List<PlanVersion>> listPlanVersions(String planId) async {
    final rows = await _client
        .from('plan_versions')
        .select()
        .eq('plan_id', planId)
        .order('round_number', ascending: true);

    return (rows as List<dynamic>).map((e) {
      final row = Map<String, dynamic>.from(e as Map);
      return PlanVersion(
        id: row['id'] as String,
        planId: row['plan_id'] as String,
        audioNoteId: row['audio_note_id'] as String,
        roundNumber: row['round_number'] as int,
        planSnapshot:
            Map<String, dynamic>.from(row['plan_snapshot'] as Map),
        transcription: row['transcription'] as String?,
        diffSummary: row['diff_summary'] as String?,
        followUpQuestions: (row['follow_up_questions'] as List?)
            ?.map((e) => e.toString())
            .toList(),
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    }).toList();
  }

  Future<Map<String, dynamic>> restorePlanVersion(String versionId) async {
    try {
      final res = await _client.functions.invoke(
        'plan-versions',
        body: {'action': 'restore', 'id': versionId},
      );
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
      return Map<String, dynamic>.from(data as Map);
    } on FunctionException catch (e) {
      throw Exception(_messageFromFunctionException(e));
    }
  }

  /// Calls the `refine-plan` Edge Function with an uploaded audio path.
  /// Returns the parsed response map with updatedPlan, newFollowUpQuestions, etc.
  Future<Map<String, dynamic>> invokePlanRefinement({
    required String planId,
    required String audioPath,
    String? followUpQuestionId,
    String? followUpQuestionText,
  }) async {
    try {
      final body = <String, dynamic>{
        'planId': planId,
        'audioPath': audioPath,
      };
      if (followUpQuestionId != null) {
        body['followUpQuestionId'] = followUpQuestionId;
      }
      if (followUpQuestionText != null) {
        // Authoritative text snapshot taken at tap-time. If the AI rewrites
        // the questions list before we submit, the index becomes stale —
        // the server will prefer this text and skip the index lookup.
        body['followUpQuestionText'] = followUpQuestionText;
      }
      final res = await _client.functions.invoke(
        kRefinePlanEdgeFunction,
        body: body,
      );
      final data = res.data;
      if (data is Map && data['error'] != null) {
        throw Exception(data['error'].toString());
      }
      return Map<String, dynamic>.from(data as Map);
    } on FunctionException catch (e) {
      throw Exception(_messageFromFunctionException(e));
    }
  }

  /// Returns `null` rows when the watched note no longer exists (deleted
  /// remotely). The bloc treats `null` as a "deleted" signal instead of a
  /// stream-killing exception so realtime updates keep working after a
  /// soft transition like restore.
  Stream<AudioNote?> watchNote(String noteId) {
    return _client
        .from('audio_notes')
        .stream(primaryKey: ['id'])
        .eq('id', noteId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return AudioNoteMapper.fromRow(Map<String, dynamic>.from(rows.first));
        });
  }
}
