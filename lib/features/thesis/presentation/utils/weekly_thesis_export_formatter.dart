import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/weekly_thesis_export.dart';

/// Localized headings for the weekly letter.
class WeeklyExportLabels {
  const WeeklyExportLabels({
    required this.currentSpeechTitle,
    required this.heardTitle,
    required this.noHeard,
    required this.untitledNote,
    required this.weekOf,
    required this.formatDate,
    required this.heardLine,
  });

  final String currentSpeechTitle;
  final String heardTitle;
  final String noHeard;
  final String untitledNote;
  final String Function(String range) weekOf;
  final String Function(DateTime date) formatDate;

  /// Label plus the date it was marked heard. Not a user id.
  final String Function(String label, String date) heardLine;
}

/// Current concept, then who heard a version in the last 7 days.
///
/// Old field paragraphs are not glued into a one-pager.
class WeeklyThesisExportFormatter {
  const WeeklyThesisExportFormatter._();

  static String letter(WeeklyThesisExport export, WeeklyExportLabels labels) {
    final title = _nonEmpty(export.thesis.title) ?? labels.untitledNote;
    final range =
        '${labels.formatDate(export.windowStart)} – ${labels.formatDate(export.windowEnd)}';
    final buf = StringBuffer()
      ..writeln('# $title')
      ..writeln(labels.weekOf(range))
      ..writeln()
      ..writeln('## ${labels.currentSpeechTitle}');

    final speech = _speechLines(export.thesis);
    if (speech.isEmpty) {
      buf.writeln(labels.untitledNote);
    } else {
      for (var i = 0; i < speech.length; i++) {
        if (i > 0) buf.writeln();
        buf.writeln(speech[i]);
      }
    }

    buf
      ..writeln()
      ..writeln('## ${labels.heardTitle}');
    final heard = export.heardVersions.where((version) => version.wasHeard);
    if (heard.isEmpty) {
      buf.writeln(labels.noHeard);
    } else {
      for (final version in heard) {
        final at = version.heardAt ?? version.createdAt;
        buf.writeln(
          '• ${labels.heardLine(version.heardByLabel!.trim(), labels.formatDate(at))}',
        );
      }
    }

    return buf.toString().trim();
  }

  static List<String> _speechLines(Thesis thesis) {
    return [
      for (final value in [
        thesis.shortSummary,
        thesis.problem,
        thesis.solution,
        thesis.targetAudience,
        thesis.businessModel,
        thesis.keyMetrics,
        thesis.advantages,
        thesis.risksGaps,
      ])
        if (_nonEmpty(value) != null) _nonEmpty(value)!,
    ];
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
