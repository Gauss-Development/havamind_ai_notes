import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/presentation/utils/plan_export_formatter.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';
import 'package:sample/features/thesis/domain/entities/weekly_thesis_export.dart';
import 'package:sample/features/thesis/domain/utils/thesis_as_startup_analysis.dart';

/// Localized headings and honest empty lines for the weekly letter.
class WeeklyExportLabels {
  const WeeklyExportLabels({
    required this.highlightsTitle,
    required this.metricsTitle,
    required this.askTitle,
    required this.untitledNote,
    required this.noMetrics,
    required this.noAsk,
    required this.debriefsThisWeek,
    required this.weekOf,
    required this.formatDate,
  });

  final String highlightsTitle;
  final String metricsTitle;
  final String askTitle;
  final String untitledNote;
  final String noMetrics;
  final String noAsk;
  final String Function(int count) debriefsThisWeek;
  final String Function(String range) weekOf;
  final String Function(DateTime date) formatDate;
}

/// Highlights / Metrics / Ask from the 7-day corpus, then
/// [PlanExportFormatter.onePager] of the living thesis — not one card.
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
      ..writeln('## ${labels.highlightsTitle}')
      ..writeln(labels.debriefsThisWeek(export.weekDebriefs.length));

    for (final note in export.weekDebriefs) {
      buf.writeln('• ${_debriefLine(note, labels)}');
    }

    final summary = _nonEmpty(export.thesis.shortSummary);
    if (summary != null) {
      buf
        ..writeln()
        ..writeln(summary);
    }

    buf
      ..writeln()
      ..writeln('## ${labels.metricsTitle}')
      ..writeln(_metricsBody(export.thesis, labels))
      ..writeln()
      ..writeln('## ${labels.askTitle}')
      ..writeln(_askBody(export.thesis, labels));

    final analysis = thesisAsStartupAnalysis(export.thesis);
    if (PlanExportFormatter.hasExportableContent(analysis)) {
      buf
        ..writeln()
        ..writeln('---')
        ..writeln()
        ..write(PlanExportFormatter.onePager(analysis));
    }

    return buf.toString().trim();
  }

  static String _debriefLine(AudioNote note, WeeklyExportLabels labels) {
    final title = _nonEmpty(note.title) ?? labels.untitledNote;
    return '$title (${labels.formatDate(note.createdAt)})';
  }

  static String _metricsBody(Thesis thesis, WeeklyExportLabels labels) {
    return _nonEmpty(thesis.keyMetrics) ?? labels.noMetrics;
  }

  static String _askBody(Thesis thesis, WeeklyExportLabels labels) {
    final script = _nonEmpty(thesis.nextConversationScript);
    if (script != null) return script;

    final questions = thesis.followUpQuestions
        ?.map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();
    if (questions != null && questions.isNotEmpty) {
      return questions.map((q) => '• $q').join('\n');
    }
    return labels.noAsk;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
