import 'dart:convert';

import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';

class StartupAnalysisMapper {
  static StartupAnalysis fromRow(Map<String, dynamic> row) {
    return StartupAnalysis(
      id: row['id'] as String,
      audioNoteId: row['audio_note_id'] as String,
      userId: row['user_id'] as String,
      shortSummary: row['short_summary'] as String?,
      startupTitle: row['startup_title'] as String?,
      problem: row['problem'] as String?,
      solution: row['solution'] as String?,
      targetAudience: row['target_audience'] as String?,
      businessModel: row['business_model'] as String?,
      keyMetrics: row['key_metrics'] as String?,
      advantages: row['advantages'] as String?,
      risksGaps: row['risks_gaps'] as String?,
      followUpQuestions: _parseQuestions(row['follow_up_questions']),
      marketPotentialScore: (row['market_potential_score'] as num?)?.toInt(),
      technicalComplexityScore:
          (row['technical_complexity_score'] as num?)?.toInt(),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  static List<String>? _parseQuestions(dynamic value) {
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
}
