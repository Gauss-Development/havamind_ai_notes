import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class WatchAudioNoteUseCase {
  WatchAudioNoteUseCase(this._repository);

  final AudioNotesRepository _repository;

  Stream<AudioNote?> call(String noteId) {
    return _repository.watchNote(noteId);
  }
}
