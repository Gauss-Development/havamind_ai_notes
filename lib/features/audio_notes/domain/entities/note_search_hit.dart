import 'package:equatable/equatable.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';

enum NoteSearchMatchType { title, transcript }

class NoteSearchHit extends Equatable {
  const NoteSearchHit({
    required this.note,
    required this.matchType,
    this.excerpt,
  });

  final AudioNote note;
  final NoteSearchMatchType matchType;
  final String? excerpt;

  @override
  List<Object?> get props => [note, matchType, excerpt];
}
