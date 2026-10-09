import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/thesis/domain/entities/thesis_version.dart';

/// Rolling window for the Sunday / “collect the week” letter.
const weekExportLookback = Duration(days: 7);

/// Instant [lookback] before [now] (inclusive lower bound via
/// [selectNotesCreatedSince]).
DateTime weekExportSince(DateTime now) => now.subtract(weekExportLookback);

/// Notes with [AudioNote.createdAt] on or after [since], newest first.
List<AudioNote> selectNotesCreatedSince(List<AudioNote> notes, DateTime since) {
  final selected = [
    for (final note in notes)
      if (!note.createdAt.isBefore(since)) note,
  ];
  selected.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return selected;
}

/// Customer-discovery notes — the week’s debriefs, not pitches or updates.
List<AudioNote> selectWeekDebriefs(List<AudioNote> weekNotes) {
  return [
    for (final note in weekNotes)
      if (note.templateId == RecordingTemplateIds.customerDiscovery) note,
  ];
}

/// Speeches marked heard inside [since, now], newest first.
/// Unheard archive rows are not included. The label is not a user id.
List<ThesisVersion> selectHeardInWindow(
  List<ThesisVersion> versions,
  DateTime since,
  DateTime now,
) {
  final selected = [
    for (final version in versions)
      if (version.wasHeard && _heardInWindow(version, since, now)) version,
  ];
  selected.sort((a, b) {
    final aAt = a.heardAt ?? a.createdAt;
    final bAt = b.heardAt ?? b.createdAt;
    return bAt.compareTo(aAt);
  });
  return selected;
}

bool _heardInWindow(ThesisVersion version, DateTime since, DateTime now) {
  final at = version.heardAt ?? version.createdAt;
  return !at.isBefore(since) && !at.isAfter(now);
}
