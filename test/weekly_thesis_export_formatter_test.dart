import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_status.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/weekly_thesis_export.dart';
import 'package:sample/features/thesis/presentation/utils/weekly_thesis_export_formatter.dart';

final _labels = WeeklyExportLabels(
  highlightsTitle: 'Highlights',
  metricsTitle: 'Metrics',
  askTitle: 'The ask',
  untitledNote: 'Untitled note',
  noMetrics: 'No metrics captured this week.',
  noAsk: 'No ask yet — the next conversation is still open.',
  debriefsThisWeek: (count) => '$count debriefs this week',
  weekOf: (range) => 'Week of $range',
  formatDate: _formatDate,
);

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

Thesis _thesis({
  String? title = 'Havamind',
  String? shortSummary = 'Living thesis for founders.',
  String? keyMetrics = 'Weekly debriefs, letters sent',
  String? nextConversationScript = 'Talk to clinic ops. Do not pitch.',
  List<String>? followUpQuestions,
  String? problem = 'Founders lose the week in one-off cards.',
}) {
  return Thesis(
    id: 'thesis-1',
    userId: 'user-1',
    title: title,
    shortSummary: shortSummary,
    problem: problem,
    keyMetrics: keyMetrics,
    nextConversationScript: nextConversationScript,
    followUpQuestions: followUpQuestions,
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 16),
  );
}

AudioNote _debrief({
  required String id,
  required DateTime createdAt,
  String title = '',
}) {
  return AudioNote(
    id: id,
    userId: 'user-1',
    title: title,
    audioPath: null,
    durationSeconds: 90,
    status: AudioNoteStatus.completed,
    createdAt: createdAt,
    updatedAt: createdAt,
    templateId: RecordingTemplateIds.customerDiscovery,
  );
}

WeeklyThesisExport _export({Thesis? thesis, List<AudioNote>? debriefs}) {
  final notes =
      debriefs ??
      [
        _debrief(
          id: 'd2',
          createdAt: DateTime.utc(2026, 9, 15),
          title: 'Clinic ops call',
        ),
        _debrief(
          id: 'd1',
          createdAt: DateTime.utc(2026, 9, 12),
          title: 'First customer',
        ),
      ];
  return WeeklyThesisExport(
    thesis: thesis ?? _thesis(),
    weekNotes: notes,
    weekDebriefs: notes,
    windowStart: DateTime.utc(2026, 9, 9),
    windowEnd: DateTime.utc(2026, 9, 16),
  );
}

void main() {
  group('WeeklyThesisExportFormatter', () {
    test('builds Highlights / Metrics / Ask from thesis + week debriefs', () {
      final text = WeeklyThesisExportFormatter.letter(_export(), _labels);

      expect(text, contains('# Havamind'));
      expect(text, contains('Week of 2026-09-09 – 2026-09-16'));
      expect(text, contains('## Highlights'));
      expect(text, contains('2 debriefs this week'));
      expect(text, contains('• Clinic ops call (2026-09-15)'));
      expect(text, contains('• First customer (2026-09-12)'));
      expect(text, contains('Living thesis for founders.'));
      expect(text, contains('## Metrics'));
      expect(text, contains('Weekly debriefs, letters sent'));
      expect(text, contains('## The ask'));
      expect(text, contains('Talk to clinic ops. Do not pitch.'));
    });

    test('reuses PlanExportFormatter one-pager for the living thesis', () {
      final text = WeeklyThesisExportFormatter.letter(_export(), _labels);

      expect(text, contains('## Elevator pitch'));
      expect(text, contains('## Problem'));
      expect(text, contains('Founders lose the week in one-off cards.'));
      expect(text, contains('Generated with Hava Mind'));
    });

    test('uses untitled fallback and honest empty metrics / ask', () {
      final text = WeeklyThesisExportFormatter.letter(
        _export(
          thesis: _thesis(
            title: '  ',
            shortSummary: null,
            keyMetrics: null,
            nextConversationScript: null,
            problem: null,
          ),
          debriefs: [_debrief(id: 'd1', createdAt: DateTime.utc(2026, 9, 14))],
        ),
        _labels,
      );

      expect(text, contains('# Untitled note'));
      expect(text, contains('1 debriefs this week'));
      expect(text, contains('• Untitled note (2026-09-14)'));
      expect(text, contains('No metrics captured this week.'));
      expect(
        text,
        contains('No ask yet — the next conversation is still open.'),
      );
      expect(text, isNot(contains('## Elevator pitch')));
    });

    test('ask falls back to follow-up questions when script is empty', () {
      final text = WeeklyThesisExportFormatter.letter(
        _export(
          thesis: _thesis(
            nextConversationScript: null,
            followUpQuestions: const ['Who pays?', 'What did they try?'],
          ),
        ),
        _labels,
      );

      expect(text, contains('• Who pays?'));
      expect(text, contains('• What did they try?'));
    });
  });
}
