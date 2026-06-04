import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';

/// Formats startup analysis into founder-facing export templates.
class PlanExportFormatter {
  const PlanExportFormatter._();

  static bool hasExportableContent(StartupAnalysis analysis) {
    return _nonEmpty(analysis.startupTitle) != null ||
        _nonEmpty(analysis.shortSummary) != null ||
        _nonEmpty(analysis.problem) != null ||
        _nonEmpty(analysis.solution) != null ||
        _nonEmpty(analysis.targetAudience) != null ||
        _nonEmpty(analysis.businessModel) != null ||
        _nonEmpty(analysis.keyMetrics) != null ||
        _nonEmpty(analysis.advantages) != null ||
        _nonEmpty(analysis.risksGaps) != null ||
        analysis.marketPotentialScore != null ||
        analysis.technicalComplexityScore != null;
  }

  static String onePager(StartupAnalysis analysis) {
    final title = _nonEmpty(analysis.startupTitle) ?? 'Startup plan';
    final buf = StringBuffer()..writeln('# $title');

    if (_nonEmpty(analysis.shortSummary) != null) {
      buf
        ..writeln()
        ..writeln('## Elevator pitch')
        ..writeln(analysis.shortSummary!.trim());
    }

    _appendSection(buf, 'Problem', analysis.problem);
    _appendSection(buf, 'Solution', analysis.solution);
    _appendSection(buf, 'Target audience', analysis.targetAudience);
    _appendSection(buf, 'Business model', analysis.businessModel);
    _appendSection(buf, 'Key metrics', analysis.keyMetrics);
    _appendSection(buf, 'Advantages', analysis.advantages);
    _appendSection(buf, 'Risks & gaps', analysis.risksGaps);

    final scores = _formatScores(analysis);
    if (scores != null) {
      buf
        ..writeln()
        ..writeln('## Signals')
        ..writeln(scores);
    }

    buf
      ..writeln()
      ..writeln('---')
      ..writeln('Generated with Hava Mind');

    return buf.toString().trim();
  }

  static String pitchBullets(StartupAnalysis analysis) {
    final title = _nonEmpty(analysis.startupTitle);
    final buf = StringBuffer();

    if (title != null) {
      buf.writeln('• $title');
    }
    if (_nonEmpty(analysis.shortSummary) != null) {
      buf.writeln('• Pitch: ${analysis.shortSummary!.trim()}');
    }

    _appendBullet(buf, 'Problem', analysis.problem);
    _appendBullet(buf, 'Solution', analysis.solution);
    _appendBullet(buf, 'Audience', analysis.targetAudience);
    _appendBullet(buf, 'Business model', analysis.businessModel);
    _appendBullet(buf, 'Metrics', analysis.keyMetrics);
    _appendBullet(buf, 'Edge', analysis.advantages);
    _appendBullet(buf, 'Risks', analysis.risksGaps);

    final scores = _formatScores(analysis);
    if (scores != null) {
      buf.writeln('• $scores');
    }

    return buf.toString().trim();
  }

  static String emailIntro(StartupAnalysis analysis) {
    final title = _nonEmpty(analysis.startupTitle) ?? 'our startup';
    final pitch = _nonEmpty(analysis.shortSummary);
    final problem = _nonEmpty(analysis.problem);
    final audience = _nonEmpty(analysis.targetAudience);
    final solution = _nonEmpty(analysis.solution);

    final buf = StringBuffer()
      ..writeln('Hi — quick intro on $title:')
      ..writeln();

    if (pitch != null) {
      buf.writeln(pitch);
      buf.writeln();
    }

    if (problem != null && audience != null && solution != null) {
      buf.writeln(
        "We're solving $problem for $audience with $solution.",
      );
    } else if (problem != null && solution != null) {
      buf.writeln("We're solving $problem with $solution.");
    } else if (problem != null) {
      buf.writeln('We are focused on $problem.');
    }

    buf
      ..writeln()
      ..writeln('Happy to share more if useful.');

    return buf.toString().trim();
  }

  static void _appendSection(StringBuffer buf, String label, String? value) {
    final text = _nonEmpty(value);
    if (text == null) return;
    buf
      ..writeln()
      ..writeln('## $label')
      ..writeln(text);
  }

  static void _appendBullet(StringBuffer buf, String label, String? value) {
    final text = _nonEmpty(value);
    if (text == null) return;
    buf.writeln('• $label: $text');
  }

  static String? _formatScores(StartupAnalysis analysis) {
    final parts = <String>[];
    if (analysis.marketPotentialScore != null) {
      parts.add('Market potential ${analysis.marketPotentialScore}%');
    }
    if (analysis.technicalComplexityScore != null) {
      parts.add('Technical complexity ${analysis.technicalComplexityScore}%');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
