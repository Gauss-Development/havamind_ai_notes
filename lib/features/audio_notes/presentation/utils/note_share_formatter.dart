import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_transcript.dart';
import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/audio_notes/presentation/widgets/audio_note_duration_formatter.dart';

/// Formats a note with its analysis and transcript into shareable plain text.
class NoteShareFormatter {
  const NoteShareFormatter._();

  static String format({
    required AudioNote note,
    AudioNoteTranscript? transcript,
    StartupAnalysis? analysis,
  }) {
    final buf = StringBuffer();

    buf.writeln(note.title);
    buf.writeln(
      'Duration: ${AudioNoteDurationFormatter.mmSs(note.durationSeconds)}',
    );
    buf.writeln();

    if (analysis != null) {
      if (analysis.shortSummary != null) {
        buf.writeln(analysis.shortSummary);
        buf.writeln();
      }

      _appendField(buf, 'Problem', analysis.problem);
      _appendField(buf, 'Solution', analysis.solution);
      _appendField(buf, 'Target Audience', analysis.targetAudience);
      _appendField(buf, 'Business Model', analysis.businessModel);
      _appendField(buf, 'Key Metrics', analysis.keyMetrics);
      _appendField(buf, 'Advantages', analysis.advantages);
      _appendField(buf, 'Risks & Gaps', analysis.risksGaps);

      if (analysis.marketPotentialScore != null) {
        buf.writeln('Market Potential: ${analysis.marketPotentialScore}%');
      }
      if (analysis.technicalComplexityScore != null) {
        buf.writeln(
          'Technical Complexity: ${analysis.technicalComplexityScore}%',
        );
      }

      if (analysis.followUpQuestions != null &&
          analysis.followUpQuestions!.isNotEmpty) {
        buf.writeln();
        buf.writeln('Follow-up Questions:');
        for (final q in analysis.followUpQuestions!) {
          buf.writeln('  • $q');
        }
      }
    }

    if (transcript != null && transcript.transcriptText.trim().isNotEmpty) {
      buf.writeln();
      buf.writeln('--- Transcript ---');
      buf.writeln(transcript.transcriptText.trim());
    }

    return buf.toString().trim();
  }

  static void _appendField(StringBuffer buf, String label, String? value) {
    if (value == null || value.trim().isEmpty) return;
    buf.writeln('$label:');
    buf.writeln(value.trim());
    buf.writeln();
  }
}
