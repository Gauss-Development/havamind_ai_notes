import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/entities/recording_template.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class SaveAudioRecordingParams {
  const SaveAudioRecordingParams({
    required this.localFilePath,
    required this.durationSeconds,
    this.templateId = RecordingTemplateIds.founderPitch,
  });

  final String localFilePath;
  final int durationSeconds;
  final String templateId;
}

class SaveAudioRecordingUseCase
    implements UseCase<AudioNote, SaveAudioRecordingParams> {
  SaveAudioRecordingUseCase(this._repository);

  final AudioNotesRepository _repository;

  @override
  Future<Either<Failure, AudioNote>> call(SaveAudioRecordingParams params) {
    return _repository.saveRecording(
      localFilePath: params.localFilePath,
      durationSeconds: params.durationSeconds,
      templateId: RecordingTemplateIds.normalize(params.templateId),
    );
  }
}
