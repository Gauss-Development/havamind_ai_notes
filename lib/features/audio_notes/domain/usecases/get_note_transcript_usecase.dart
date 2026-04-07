import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note_transcript.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class GetNoteTranscriptUseCase
    implements UseCase<AudioNoteTranscript?, String> {
  GetNoteTranscriptUseCase(this._repository);

  final AudioNotesRepository _repository;

  @override
  Future<Either<Failure, AudioNoteTranscript?>> call(String noteId) {
    return _repository.getTranscript(noteId);
  }
}
