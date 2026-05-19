import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/audio_note.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class SearchNotesByTitleParams {
  const SearchNotesByTitleParams({required this.query, this.limit = 20});

  final String query;
  final int limit;
}

class SearchNotesByTitleUseCase
    implements UseCase<List<AudioNote>, SearchNotesByTitleParams> {
  SearchNotesByTitleUseCase(this._repository);

  final AudioNotesRepository _repository;

  @override
  Future<Either<Failure, List<AudioNote>>> call(
    SearchNotesByTitleParams params,
  ) {
    return _repository.searchNotesByTitle(
      query: params.query,
      limit: params.limit,
    );
  }
}
