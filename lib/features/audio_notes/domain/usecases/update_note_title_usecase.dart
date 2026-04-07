import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class UpdateNoteTitleParams {
  const UpdateNoteTitleParams({
    required this.noteId,
    required this.title,
  });

  final String noteId;
  final String title;
}

class UpdateNoteTitleUseCase implements UseCase<Unit, UpdateNoteTitleParams> {
  UpdateNoteTitleUseCase(this._repository);

  final AudioNotesRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(UpdateNoteTitleParams params) {
    return _repository.updateNoteTitle(
      noteId: params.noteId,
      title: params.title,
    );
  }
}
