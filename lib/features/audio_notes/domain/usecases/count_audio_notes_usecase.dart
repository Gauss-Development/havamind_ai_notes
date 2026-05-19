import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class CountAudioNotesUseCase implements UseCase<int, NoParams> {
  CountAudioNotesUseCase(this._repository);

  final AudioNotesRepository _repository;

  @override
  Future<Either<Failure, int>> call(NoParams params) {
    return _repository.countNotes();
  }
}
