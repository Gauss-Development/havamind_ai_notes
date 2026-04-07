import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/tags/domain/entities/note_tag.dart';

abstract class TagsRepository {
  Future<Either<Failure, List<NoteTag>>> listTags();

  Future<Either<Failure, NoteTag>> createTag(String name);

  Future<Either<Failure, Unit>> deleteTag(String tagId);

  Future<Either<Failure, List<String>>> getTagIdsForNote(String noteId);

  Future<Either<Failure, Unit>> setTagsForNote(
    String noteId,
    List<String> tagIds,
  );
}
