import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sample/features/tags/domain/entities/note_tag.dart';
import 'package:sample/features/tags/domain/repositories/tags_repository.dart';

class TagsState extends Equatable {
  const TagsState({this.tags = const [], this.isLoading = false, this.error});

  final List<NoteTag> tags;
  final bool isLoading;
  final String? error;

  TagsState copyWith({List<NoteTag>? tags, bool? isLoading, String? error}) {
    return TagsState(
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [tags, isLoading, error];
}

class TagsCubit extends Cubit<TagsState> {
  TagsCubit({required TagsRepository repository})
    : _repository = repository,
      super(const TagsState());

  final TagsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final result = await _repository.listTags();
    result.fold(
      (f) => emit(state.copyWith(isLoading: false, error: f.message)),
      (tags) => emit(state.copyWith(tags: tags, isLoading: false)),
    );
  }

  Future<void> create(String name) async {
    final result = await _repository.createTag(name);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (tag) => emit(state.copyWith(tags: [...state.tags, tag])),
    );
  }

  Future<void> delete(String tagId) async {
    final result = await _repository.deleteTag(tagId);
    result.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (_) => emit(
        state.copyWith(tags: state.tags.where((t) => t.id != tagId).toList()),
      ),
    );
  }

  Future<List<String>> getTagIdsForNote(String noteId) async {
    final result = await _repository.getTagIdsForNote(noteId);
    return result.fold((_) => [], (ids) => ids);
  }

  Future<void> setTagsForNote(String noteId, List<String> tagIds) async {
    final result = await _repository.setTagsForNote(noteId, tagIds);
    result.fold((f) => emit(state.copyWith(error: f.message)), (_) {});
  }
}
