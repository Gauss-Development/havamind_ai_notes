import 'package:equatable/equatable.dart';

import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';

/// A completed note-level analysis that can seed a missing thesis.
class ThesisSeedCandidate extends Equatable {
  const ThesisSeedCandidate({
    required this.analysis,
    required this.noteCreatedAt,
  });

  final StartupAnalysis analysis;
  final DateTime noteCreatedAt;

  @override
  List<Object?> get props => [analysis, noteCreatedAt];
}
