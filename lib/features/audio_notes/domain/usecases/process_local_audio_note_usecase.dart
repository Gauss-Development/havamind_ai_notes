import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class ProcessLocalAudioNoteParams {
  const ProcessLocalAudioNoteParams({
    required this.localFilePath,
    required this.durationSeconds,
  });

  final String localFilePath;
  final int durationSeconds;
}

class ProcessLocalAudioNoteUseCase
    implements UseCase<AudioNote, ProcessLocalAudioNoteParams> {
  ProcessLocalAudioNoteUseCase(this._repository);

  final AudioNotesRepository _repository;

  @override
  Future<Either<Failure, AudioNote>> call(ProcessLocalAudioNoteParams params) {
    return _repository.processLocalAudioNote(
      localFilePath: params.localFilePath,
      durationSeconds: params.durationSeconds,
    );
  }
}
