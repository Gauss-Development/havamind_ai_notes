import 'package:equatable/equatable.dart';

import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/thesis/domain/entities/thesis.dart';

/// Current thesis plus notes created in the last 7 days.
///
/// The letter is honest only when [weekDebriefs] is not empty.
class WeeklyThesisExport extends Equatable {
  const WeeklyThesisExport({
    required this.thesis,
    required this.weekNotes,
    required this.weekDebriefs,
    required this.windowStart,
    required this.windowEnd,
  });

  final Thesis thesis;
  final List<AudioNote> weekNotes;
  final List<AudioNote> weekDebriefs;
  final DateTime windowStart;
  final DateTime windowEnd;

  bool get hasDebriefs => weekDebriefs.isNotEmpty;

  @override
  List<Object?> get props => [
    thesis,
    weekNotes,
    weekDebriefs,
    windowStart,
    windowEnd,
  ];
}
