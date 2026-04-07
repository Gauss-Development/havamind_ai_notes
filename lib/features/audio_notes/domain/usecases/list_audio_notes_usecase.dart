import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class ListAudioNotesParams {
  const ListAudioNotesParams({this.limit = 20, this.offset = 0});

  final int limit;
  final int offset;
}

class ListAudioNotesUseCase
    implements UseCase<List<AudioNote>, ListAudioNotesParams> {
  ListAudioNotesUseCase(this._repository);

  final AudioNotesRepository _repository;

  @override
  Future<Either<Failure, List<AudioNote>>> call(
    ListAudioNotesParams params,
  ) {
    return _repository.listNotes(limit: params.limit, offset: params.offset);
  }
}
