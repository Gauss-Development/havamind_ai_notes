import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class GetAudioNoteParams {
  const GetAudioNoteParams(this.id);
  final String id;
}

class GetAudioNoteUseCase implements UseCase<AudioNote, GetAudioNoteParams> {
  GetAudioNoteUseCase(this._repository);

  final AudioNotesRepository _repository;

  @override
  Future<Either<Failure, AudioNote>> call(GetAudioNoteParams params) {
    return _repository.getNote(params.id);
  }
}
