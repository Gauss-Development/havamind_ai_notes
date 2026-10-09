import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/thesis/data/models/thesis_mapper.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';

void main() {
  test('fromRow maps debrief and share counters', () {
    final thesis = ThesisMapper.fromRow({
      'id': 'thesis-1',
      'user_id': 'user-1',
      'title': 'Havamind',
      'short_summary': null,
      'problem': null,
      'solution': null,
      'target_audience': null,
      'business_model': null,
      'key_metrics': null,
      'advantages': null,
      'risks_gaps': null,
      'follow_up_questions': null,
      'next_conversation_script': null,
      'field_evidence': {},
      'debrief_count': 2,
      'week_artifact_share_count': 1,
      'week_artifact_shared_at': '2026-09-16T12:00:00Z',
      'created_at': '2026-09-01T00:00:00Z',
      'updated_at': '2026-09-16T12:00:00Z',
    });

    expect(thesis.debriefCount, 2);
    expect(thesis.weekArtifactShareCount, 1);
    expect(thesis.weekArtifactSharedAt, DateTime.parse('2026-09-16T12:00:00Z'));
  });

  test('fromRow defaults missing counters to zero', () {
    final thesis = ThesisMapper.fromRow({
      'id': 'thesis-1',
      'user_id': 'user-1',
      'field_evidence': {},
      'created_at': '2026-09-01T00:00:00Z',
      'updated_at': '2026-09-16T12:00:00Z',
    });

    expect(thesis.debriefCount, 0);
    expect(thesis.weekArtifactShareCount, 0);
    expect(thesis.weekArtifactSharedAt, isNull);
  });

  test('versionFromRow keeps the source template for debrief counts', () {
    final version = ThesisMapper.versionFromRow({
      'id': 'v1',
      'thesis_id': 'thesis-1',
      'user_id': 'user-1',
      'round_number': 1,
      'thesis_snapshot': {'title': 'Havamind'},
      'transcription': 'clinic call',
      'diff_summary': null,
      'follow_up_questions': null,
      'source_note_id': 'note-1',
      'source_template_id': RecordingTemplateIds.customerDiscovery,
      'created_at': '2026-09-14T00:00:00Z',
    });

    expect(version.sourceNoteId, 'note-1');
    expect(version.sourceTemplateId, RecordingTemplateIds.customerDiscovery);
    expect(version.hearingStatus, HearingStatus.unheard);
    expect(version.heardByLabel, isNull);
    expect(version.heardAt, isNull);
  });

  test('versionFromRow reads a confirmed hearer and trims the label', () {
    final version = ThesisMapper.versionFromRow({
      'id': 'v2',
      'thesis_id': 'thesis-1',
      'user_id': 'user-1',
      'round_number': 2,
      'thesis_snapshot': {'business_model': 'Clinics pay monthly'},
      'transcription': 'pitch',
      'hearing_status': 'heard',
      'heard_by_label': ' Маша ',
      'heard_at': '2026-10-09T07:00:00Z',
      'created_at': '2026-10-09T07:00:00Z',
    });

    expect(version.hearingStatus, HearingStatus.heard);
    expect(version.heardByLabel, 'Маша');
    expect(version.heardAt, DateTime.parse('2026-10-09T07:00:00Z'));
    expect(version.wasHeard, isTrue);
    expect(version.userId, 'user-1');
  });

  test('parseNonNegInt rejects negatives and non-numbers', () {
    expect(ThesisMapper.parseNonNegInt(-2), 0);
    expect(ThesisMapper.parseNonNegInt(2.9), 2);
    expect(ThesisMapper.parseNonNegInt('x'), 0);
  });
}
