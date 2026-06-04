import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/core/usecases/usecase.dart';
import 'package:sample/features/audio_notes/domain/entities/note_search_hit.dart';
import 'package:sample/features/audio_notes/domain/repositories/audio_notes_repository.dart';

class SearchNotesParams {
  const SearchNotesParams({required this.query, this.limit = 20});

  final String query;
  final int limit;
}

class SearchNotesUseCase
    implements UseCase<List<NoteSearchHit>, SearchNotesParams> {
  SearchNotesUseCase(this._repository);

  final AudioNotesRepository _repository;

  @override
  Future<Either<Failure, List<NoteSearchHit>>> call(
    SearchNotesParams params,
  ) {
    return _repository.searchNotes(
      query: params.query,
      limit: params.limit,
    );
  }
}
