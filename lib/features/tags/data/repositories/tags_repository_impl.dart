import 'package:dartz/dartz.dart';
import 'package:sample/core/error/failure.dart';
import 'package:sample/features/tags/data/datasources/tags_remote_data_source.dart';
import 'package:sample/features/tags/domain/entities/note_tag.dart';
import 'package:sample/features/tags/domain/repositories/tags_repository.dart';

class TagsRepositoryImpl implements TagsRepository {
  TagsRepositoryImpl({required TagsRemoteDataSource remote}) : _remote = remote;

  final TagsRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<NoteTag>>> listTags() async {
    try {
      final tags = await _remote.listTags();
      return Right(tags);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteTag>> createTag(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Left(UnexpectedFailure('Tag name cannot be empty'));
    }
    try {
      final tag = await _remote.createTag(trimmed);
      return Right(tag);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTag(String tagId) async {
    try {
      await _remote.deleteTag(tagId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getTagIdsForNote(String noteId) async {
    try {
      final ids = await _remote.getTagIdsForNote(noteId);
      return Right(ids);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setTagsForNote(
    String noteId,
    List<String> tagIds,
  ) async {
    try {
      await _remote.setTagsForNote(noteId, tagIds);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
