import 'dart:convert';

import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_field_evidence.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';

class ThesisMapper {
  static Thesis fromRow(Map<String, dynamic> row) {
    return Thesis(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String?,
      shortSummary: row['short_summary'] as String?,
      problem: row['problem'] as String?,
      solution: row['solution'] as String?,
      targetAudience: row['target_audience'] as String?,
      businessModel: row['business_model'] as String?,
      keyMetrics: row['key_metrics'] as String?,
      advantages: row['advantages'] as String?,
      risksGaps: row['risks_gaps'] as String?,
      followUpQuestions: parseStringList(row['follow_up_questions']),
      nextConversationScript: row['next_conversation_script'] as String?,
      fieldEvidence: evidenceFromJson(row['field_evidence']),
      debriefCount: parseNonNegInt(row['debrief_count']),
      weekArtifactShareCount: parseNonNegInt(row['week_artifact_share_count']),
      weekArtifactSharedAt: parseTimestamp(row['week_artifact_shared_at']),
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  static ThesisVersion versionFromRow(Map<String, dynamic> row) {
    return ThesisVersion(
      id: row['id'] as String,
      thesisId: row['thesis_id'] as String,
      userId: row['user_id'] as String,
      roundNumber: row['round_number'] as int,
      thesisSnapshot: Map<String, dynamic>.from(row['thesis_snapshot'] as Map),
      transcription: row['transcription'] as String,
      diffSummary: row['diff_summary'] as String?,
      followUpQuestions: parseStringList(row['follow_up_questions']),
      sourceNoteId: row['source_note_id'] as String?,
      sourceTemplateId: row['source_template_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  static int parseNonNegInt(dynamic value) {
    if (value is int) return value < 0 ? 0 : value;
    if (value is num) {
      final parsed = value.toInt();
      return parsed < 0 ? 0 : parsed;
    }
    return 0;
  }

  static DateTime? parseTimestamp(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static Map<String, dynamic> draftToInsert(ThesisDraft draft) {
    return {
      'title': draft.title,
      'short_summary': draft.shortSummary,
      'problem': draft.problem,
      'solution': draft.solution,
      'target_audience': draft.targetAudience,
      'business_model': draft.businessModel,
      'key_metrics': draft.keyMetrics,
      'advantages': draft.advantages,
      'risks_gaps': draft.risksGaps,
      'follow_up_questions': draft.followUpQuestions,
      'next_conversation_script': draft.nextConversationScript,
      'field_evidence': evidenceToJson(draft.fieldEvidence),
    };
  }

  static Map<String, ThesisFieldEvidence> evidenceFromJson(dynamic value) {
    final map = _asStringKeyedMap(value);
    if (map == null) return const {};

    final evidence = <String, ThesisFieldEvidence>{};
    map.forEach((key, raw) {
      final entry = _evidenceEntry(raw);
      if (entry != null) {
        evidence[key] = entry;
      }
    });
    return evidence;
  }

  static Map<String, dynamic> evidenceToJson(
    Map<String, ThesisFieldEvidence> evidence,
  ) {
    return evidence.map(
      (key, value) => MapEntry(key, {
        'kind': value.kind.dbValue,
        'quote': value.quote,
        'note_id': value.noteId,
      }),
    );
  }

  static List<String>? parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    return null;
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return null;
  }

  static ThesisFieldEvidence? _evidenceEntry(dynamic value) {
    if (value is! Map) return null;
    final map = Map<String, dynamic>.from(value);
    final kindRaw = map['kind'] as String?;
    if (kindRaw == null) return null;
    return ThesisFieldEvidence(
      kind: ThesisEvidenceKind.fromDb(kindRaw),
      quote: map['quote'] as String?,
      noteId: map['note_id'] as String?,
    );
  }
}
