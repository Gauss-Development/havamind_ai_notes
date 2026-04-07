import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class GetNoteAnalysisUseCase implements UseCase<StartupAnalysis?, String> {
  GetNoteAnalysisUseCase(this._repository);

  final AudioNotesRepository _repository;

  @override
  Future<Either<Failure, StartupAnalysis?>> call(String noteId) {
    return _repository.getAnalysis(noteId);
  }
}
