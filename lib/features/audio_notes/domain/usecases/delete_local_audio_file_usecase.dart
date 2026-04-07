import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class DeleteLocalAudioFileUseCase implements UseCase<Unit, String> {
  DeleteLocalAudioFileUseCase(this._repository);

  final AudioNotesRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String noteId) {
    return _repository.deleteLocalAudioFile(noteId);
  }
}
