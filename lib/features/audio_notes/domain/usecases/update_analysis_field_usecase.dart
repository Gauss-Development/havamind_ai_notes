import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/startup_analysis.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class UpdateAnalysisFieldParams {
  const UpdateAnalysisFieldParams({
    required this.noteId,
    required this.field,
    required this.value,
  });

  final String noteId;
  final StartupAnalysisEditableField field;
  final String value;
}

class UpdateAnalysisFieldUseCase
    implements UseCase<Unit, UpdateAnalysisFieldParams> {
  UpdateAnalysisFieldUseCase(this._repository);

  final AudioNotesRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(UpdateAnalysisFieldParams params) {
    return _repository.updateAnalysisField(
      noteId: params.noteId,
      field: params.field,
      value: params.value,
    );
  }
}
