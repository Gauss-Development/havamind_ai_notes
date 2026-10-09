import 'package:flutter_test/flutter_test.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';
import 'package:sample/features/thesis/domain/entities/weekly_thesis_export.dart';
import 'package:sample/features/thesis/presentation/utils/weekly_thesis_export_formatter.dart';

final _labels = WeeklyExportLabels(
  currentSpeechTitle: 'What you\'ll say next',
  heardTitle: 'Who heard it',
  noHeard: 'No one heard a version this week.',
  untitledNote: 'Untitled note',
  weekOf: (range) => 'Week of $range',
  formatDate: _formatDate,
  heardLine: (label, date) => 'This version was heard by: $label ($date)',
);

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

Thesis _thesis({
  String? title = 'Havamind',
  String? shortSummary = 'Clinics pay monthly',
  String? problem = 'Doctors wait 3 weeks',
  String? keyMetrics,
}) {
  return Thesis(
    id: 'thesis-1',
    userId: 'user-1',
    title: title,
    shortSummary: shortSummary,
    problem: problem,
    keyMetrics: keyMetrics,
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 16),
  );
}

ThesisVersion _heard({
  required String id,
  required String label,
  required DateTime heardAt,
  String businessModel = 'Clinics pay monthly',
}) {
  return ThesisVersion(
    id: id,
    thesisId: 'thesis-1',
    userId: 'user-1',
    roundNumber: 1,
    thesisSnapshot: {'business_model': businessModel},
    transcription: 'the pitch',
    hearingStatus: HearingStatus.heard,
    heardByLabel: label,
    heardAt: heardAt,
    createdAt: heardAt,
  );
}

WeeklyThesisExport _export({
  Thesis? thesis,
  List<ThesisVersion> heard = const [],
}) {
  return WeeklyThesisExport(
    thesis: thesis ?? _thesis(),
    weekNotes: const [],
    weekDebriefs: const [],
    windowStart: DateTime.utc(2026, 9, 9),
    windowEnd: DateTime.utc(2026, 9, 16),
    heardVersions: heard,
  );
}

void main() {
  group('WeeklyThesisExportFormatter', () {
    test('prints the current speech and who heard a version this week', () {
      final text = WeeklyThesisExportFormatter.letter(
        _export(
          heard: [
            _heard(id: 'v1', label: 'Маша', heardAt: DateTime.utc(2026, 9, 14)),
          ],
        ),
        _labels,
      );

      expect(text, contains('# Havamind'));
      expect(text, contains('Week of 2026-09-09 – 2026-09-16'));
      expect(text, contains('## What you\'ll say next'));
      expect(text, contains('Clinics pay monthly'));
      expect(text, contains('Doctors wait 3 weeks'));
      expect(text, contains('## Who heard it'));
      expect(text, contains('• This version was heard by: Маша (2026-09-14)'));
      expect(text, isNot(contains('## Elevator pitch')));
      expect(text, isNot(contains('Generated with Hava Mind')));
      expect(
        text,
        isNot(contains('Clinics pay monthly\nDoctors wait 3 weeks')),
      );
    });

    test('does not paste an old heard paragraph into the current speech', () {
      final text = WeeklyThesisExportFormatter.letter(
        _export(
          thesis: _thesis(shortSummary: 'Doctors wait 3 weeks', problem: null),
          heard: [
            _heard(
              id: 'v1',
              label: 'Маша',
              heardAt: DateTime.utc(2026, 9, 14),
              businessModel: 'Clinics pay monthly',
            ),
          ],
        ),
        _labels,
      );

      expect(text, contains('Doctors wait 3 weeks'));
      expect(text, isNot(contains('Clinics pay monthly')));
      expect(text, contains('Маша'));
    });

    test('says when nobody heard a version in the window', () {
      final text = WeeklyThesisExportFormatter.letter(
        _export(
          thesis: _thesis(title: '  ', shortSummary: null, problem: null),
        ),
        _labels,
      );

      expect(text, contains('# Untitled note'));
      expect(text, contains('No one heard a version this week.'));
      expect(text, isNot(contains('## Elevator pitch')));
    });
  });
}
