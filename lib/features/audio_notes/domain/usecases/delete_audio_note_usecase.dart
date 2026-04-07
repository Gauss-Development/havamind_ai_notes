import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class DeleteAudioNoteParams {
  const DeleteAudioNoteParams(this.id);
  final String id;
}

class DeleteAudioNoteUseCase implements UseCase<Unit, DeleteAudioNoteParams> {
  DeleteAudioNoteUseCase(this._repository);

  final AudioNotesRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(DeleteAudioNoteParams params) {
    return _repository.deleteNote(params.id);
  }
}
