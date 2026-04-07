// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'note_detail_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$NoteDetailEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId) loadRequested,
    required TResult Function() deleteRequested,
    required TResult Function() retryProcessing,
    required TResult Function() deleteLocalAudioRequested,
    required TResult Function(StartupAnalysisEditableField field, String value)
    analysisFieldUpdated,
    required TResult Function(String title) titleUpdated,
    required TResult Function(AudioNote note) noteUpdated,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId)? loadRequested,
    TResult? Function()? deleteRequested,
    TResult? Function()? retryProcessing,
    TResult? Function()? deleteLocalAudioRequested,
    TResult? Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult? Function(String title)? titleUpdated,
    TResult? Function(AudioNote note)? noteUpdated,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId)? loadRequested,
    TResult Function()? deleteRequested,
    TResult Function()? retryProcessing,
    TResult Function()? deleteLocalAudioRequested,
    TResult Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult Function(String title)? titleUpdated,
    TResult Function(AudioNote note)? noteUpdated,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadRequested value) loadRequested,
    required TResult Function(_DeleteRequested value) deleteRequested,
    required TResult Function(_RetryProcessing value) retryProcessing,
    required TResult Function(_DeleteLocalAudioRequested value)
    deleteLocalAudioRequested,
    required TResult Function(_AnalysisFieldUpdated value) analysisFieldUpdated,
    required TResult Function(_TitleUpdated value) titleUpdated,
    required TResult Function(_NoteUpdated value) noteUpdated,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadRequested value)? loadRequested,
    TResult? Function(_DeleteRequested value)? deleteRequested,
    TResult? Function(_RetryProcessing value)? retryProcessing,
    TResult? Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult? Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult? Function(_TitleUpdated value)? titleUpdated,
    TResult? Function(_NoteUpdated value)? noteUpdated,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadRequested value)? loadRequested,
    TResult Function(_DeleteRequested value)? deleteRequested,
    TResult Function(_RetryProcessing value)? retryProcessing,
    TResult Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult Function(_TitleUpdated value)? titleUpdated,
    TResult Function(_NoteUpdated value)? noteUpdated,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteDetailEventCopyWith<$Res> {
  factory $NoteDetailEventCopyWith(
    NoteDetailEvent value,
    $Res Function(NoteDetailEvent) then,
  ) = _$NoteDetailEventCopyWithImpl<$Res, NoteDetailEvent>;
}

/// @nodoc
class _$NoteDetailEventCopyWithImpl<$Res, $Val extends NoteDetailEvent>
    implements $NoteDetailEventCopyWith<$Res> {
  _$NoteDetailEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$LoadRequestedImplCopyWith<$Res> {
  factory _$$LoadRequestedImplCopyWith(
    _$LoadRequestedImpl value,
    $Res Function(_$LoadRequestedImpl) then,
  ) = __$$LoadRequestedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String noteId});
}

/// @nodoc
class __$$LoadRequestedImplCopyWithImpl<$Res>
    extends _$NoteDetailEventCopyWithImpl<$Res, _$LoadRequestedImpl>
    implements _$$LoadRequestedImplCopyWith<$Res> {
  __$$LoadRequestedImplCopyWithImpl(
    _$LoadRequestedImpl _value,
    $Res Function(_$LoadRequestedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? noteId = null}) {
    return _then(
      _$LoadRequestedImpl(
        null == noteId
            ? _value.noteId
            : noteId // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$LoadRequestedImpl implements _LoadRequested {
  const _$LoadRequestedImpl(this.noteId);

  @override
  final String noteId;

  @override
  String toString() {
    return 'NoteDetailEvent.loadRequested(noteId: $noteId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadRequestedImpl &&
            (identical(other.noteId, noteId) || other.noteId == noteId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, noteId);

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadRequestedImplCopyWith<_$LoadRequestedImpl> get copyWith =>
      __$$LoadRequestedImplCopyWithImpl<_$LoadRequestedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId) loadRequested,
    required TResult Function() deleteRequested,
    required TResult Function() retryProcessing,
    required TResult Function() deleteLocalAudioRequested,
    required TResult Function(StartupAnalysisEditableField field, String value)
    analysisFieldUpdated,
    required TResult Function(String title) titleUpdated,
    required TResult Function(AudioNote note) noteUpdated,
  }) {
    return loadRequested(noteId);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId)? loadRequested,
    TResult? Function()? deleteRequested,
    TResult? Function()? retryProcessing,
    TResult? Function()? deleteLocalAudioRequested,
    TResult? Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult? Function(String title)? titleUpdated,
    TResult? Function(AudioNote note)? noteUpdated,
  }) {
    return loadRequested?.call(noteId);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId)? loadRequested,
    TResult Function()? deleteRequested,
    TResult Function()? retryProcessing,
    TResult Function()? deleteLocalAudioRequested,
    TResult Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult Function(String title)? titleUpdated,
    TResult Function(AudioNote note)? noteUpdated,
    required TResult orElse(),
  }) {
    if (loadRequested != null) {
      return loadRequested(noteId);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadRequested value) loadRequested,
    required TResult Function(_DeleteRequested value) deleteRequested,
    required TResult Function(_RetryProcessing value) retryProcessing,
    required TResult Function(_DeleteLocalAudioRequested value)
    deleteLocalAudioRequested,
    required TResult Function(_AnalysisFieldUpdated value) analysisFieldUpdated,
    required TResult Function(_TitleUpdated value) titleUpdated,
    required TResult Function(_NoteUpdated value) noteUpdated,
  }) {
    return loadRequested(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadRequested value)? loadRequested,
    TResult? Function(_DeleteRequested value)? deleteRequested,
    TResult? Function(_RetryProcessing value)? retryProcessing,
    TResult? Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult? Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult? Function(_TitleUpdated value)? titleUpdated,
    TResult? Function(_NoteUpdated value)? noteUpdated,
  }) {
    return loadRequested?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadRequested value)? loadRequested,
    TResult Function(_DeleteRequested value)? deleteRequested,
    TResult Function(_RetryProcessing value)? retryProcessing,
    TResult Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult Function(_TitleUpdated value)? titleUpdated,
    TResult Function(_NoteUpdated value)? noteUpdated,
    required TResult orElse(),
  }) {
    if (loadRequested != null) {
      return loadRequested(this);
    }
    return orElse();
  }
}

abstract class _LoadRequested implements NoteDetailEvent {
  const factory _LoadRequested(final String noteId) = _$LoadRequestedImpl;

  String get noteId;

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadRequestedImplCopyWith<_$LoadRequestedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DeleteRequestedImplCopyWith<$Res> {
  factory _$$DeleteRequestedImplCopyWith(
    _$DeleteRequestedImpl value,
    $Res Function(_$DeleteRequestedImpl) then,
  ) = __$$DeleteRequestedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$DeleteRequestedImplCopyWithImpl<$Res>
    extends _$NoteDetailEventCopyWithImpl<$Res, _$DeleteRequestedImpl>
    implements _$$DeleteRequestedImplCopyWith<$Res> {
  __$$DeleteRequestedImplCopyWithImpl(
    _$DeleteRequestedImpl _value,
    $Res Function(_$DeleteRequestedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$DeleteRequestedImpl implements _DeleteRequested {
  const _$DeleteRequestedImpl();

  @override
  String toString() {
    return 'NoteDetailEvent.deleteRequested()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$DeleteRequestedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId) loadRequested,
    required TResult Function() deleteRequested,
    required TResult Function() retryProcessing,
    required TResult Function() deleteLocalAudioRequested,
    required TResult Function(StartupAnalysisEditableField field, String value)
    analysisFieldUpdated,
    required TResult Function(String title) titleUpdated,
    required TResult Function(AudioNote note) noteUpdated,
  }) {
    return deleteRequested();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId)? loadRequested,
    TResult? Function()? deleteRequested,
    TResult? Function()? retryProcessing,
    TResult? Function()? deleteLocalAudioRequested,
    TResult? Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult? Function(String title)? titleUpdated,
    TResult? Function(AudioNote note)? noteUpdated,
  }) {
    return deleteRequested?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId)? loadRequested,
    TResult Function()? deleteRequested,
    TResult Function()? retryProcessing,
    TResult Function()? deleteLocalAudioRequested,
    TResult Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult Function(String title)? titleUpdated,
    TResult Function(AudioNote note)? noteUpdated,
    required TResult orElse(),
  }) {
    if (deleteRequested != null) {
      return deleteRequested();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadRequested value) loadRequested,
    required TResult Function(_DeleteRequested value) deleteRequested,
    required TResult Function(_RetryProcessing value) retryProcessing,
    required TResult Function(_DeleteLocalAudioRequested value)
    deleteLocalAudioRequested,
    required TResult Function(_AnalysisFieldUpdated value) analysisFieldUpdated,
    required TResult Function(_TitleUpdated value) titleUpdated,
    required TResult Function(_NoteUpdated value) noteUpdated,
  }) {
    return deleteRequested(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadRequested value)? loadRequested,
    TResult? Function(_DeleteRequested value)? deleteRequested,
    TResult? Function(_RetryProcessing value)? retryProcessing,
    TResult? Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult? Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult? Function(_TitleUpdated value)? titleUpdated,
    TResult? Function(_NoteUpdated value)? noteUpdated,
  }) {
    return deleteRequested?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadRequested value)? loadRequested,
    TResult Function(_DeleteRequested value)? deleteRequested,
    TResult Function(_RetryProcessing value)? retryProcessing,
    TResult Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult Function(_TitleUpdated value)? titleUpdated,
    TResult Function(_NoteUpdated value)? noteUpdated,
    required TResult orElse(),
  }) {
    if (deleteRequested != null) {
      return deleteRequested(this);
    }
    return orElse();
  }
}

abstract class _DeleteRequested implements NoteDetailEvent {
  const factory _DeleteRequested() = _$DeleteRequestedImpl;
}

/// @nodoc
abstract class _$$RetryProcessingImplCopyWith<$Res> {
  factory _$$RetryProcessingImplCopyWith(
    _$RetryProcessingImpl value,
    $Res Function(_$RetryProcessingImpl) then,
  ) = __$$RetryProcessingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$RetryProcessingImplCopyWithImpl<$Res>
    extends _$NoteDetailEventCopyWithImpl<$Res, _$RetryProcessingImpl>
    implements _$$RetryProcessingImplCopyWith<$Res> {
  __$$RetryProcessingImplCopyWithImpl(
    _$RetryProcessingImpl _value,
    $Res Function(_$RetryProcessingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$RetryProcessingImpl implements _RetryProcessing {
  const _$RetryProcessingImpl();

  @override
  String toString() {
    return 'NoteDetailEvent.retryProcessing()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$RetryProcessingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId) loadRequested,
    required TResult Function() deleteRequested,
    required TResult Function() retryProcessing,
    required TResult Function() deleteLocalAudioRequested,
    required TResult Function(StartupAnalysisEditableField field, String value)
    analysisFieldUpdated,
    required TResult Function(String title) titleUpdated,
    required TResult Function(AudioNote note) noteUpdated,
  }) {
    return retryProcessing();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId)? loadRequested,
    TResult? Function()? deleteRequested,
    TResult? Function()? retryProcessing,
    TResult? Function()? deleteLocalAudioRequested,
    TResult? Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult? Function(String title)? titleUpdated,
    TResult? Function(AudioNote note)? noteUpdated,
  }) {
    return retryProcessing?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId)? loadRequested,
    TResult Function()? deleteRequested,
    TResult Function()? retryProcessing,
    TResult Function()? deleteLocalAudioRequested,
    TResult Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult Function(String title)? titleUpdated,
    TResult Function(AudioNote note)? noteUpdated,
    required TResult orElse(),
  }) {
    if (retryProcessing != null) {
      return retryProcessing();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadRequested value) loadRequested,
    required TResult Function(_DeleteRequested value) deleteRequested,
    required TResult Function(_RetryProcessing value) retryProcessing,
    required TResult Function(_DeleteLocalAudioRequested value)
    deleteLocalAudioRequested,
    required TResult Function(_AnalysisFieldUpdated value) analysisFieldUpdated,
    required TResult Function(_TitleUpdated value) titleUpdated,
    required TResult Function(_NoteUpdated value) noteUpdated,
  }) {
    return retryProcessing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadRequested value)? loadRequested,
    TResult? Function(_DeleteRequested value)? deleteRequested,
    TResult? Function(_RetryProcessing value)? retryProcessing,
    TResult? Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult? Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult? Function(_TitleUpdated value)? titleUpdated,
    TResult? Function(_NoteUpdated value)? noteUpdated,
  }) {
    return retryProcessing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadRequested value)? loadRequested,
    TResult Function(_DeleteRequested value)? deleteRequested,
    TResult Function(_RetryProcessing value)? retryProcessing,
    TResult Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult Function(_TitleUpdated value)? titleUpdated,
    TResult Function(_NoteUpdated value)? noteUpdated,
    required TResult orElse(),
  }) {
    if (retryProcessing != null) {
      return retryProcessing(this);
    }
    return orElse();
  }
}

abstract class _RetryProcessing implements NoteDetailEvent {
  const factory _RetryProcessing() = _$RetryProcessingImpl;
}

/// @nodoc
abstract class _$$DeleteLocalAudioRequestedImplCopyWith<$Res> {
  factory _$$DeleteLocalAudioRequestedImplCopyWith(
    _$DeleteLocalAudioRequestedImpl value,
    $Res Function(_$DeleteLocalAudioRequestedImpl) then,
  ) = __$$DeleteLocalAudioRequestedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$DeleteLocalAudioRequestedImplCopyWithImpl<$Res>
    extends _$NoteDetailEventCopyWithImpl<$Res, _$DeleteLocalAudioRequestedImpl>
    implements _$$DeleteLocalAudioRequestedImplCopyWith<$Res> {
  __$$DeleteLocalAudioRequestedImplCopyWithImpl(
    _$DeleteLocalAudioRequestedImpl _value,
    $Res Function(_$DeleteLocalAudioRequestedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$DeleteLocalAudioRequestedImpl implements _DeleteLocalAudioRequested {
  const _$DeleteLocalAudioRequestedImpl();

  @override
  String toString() {
    return 'NoteDetailEvent.deleteLocalAudioRequested()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeleteLocalAudioRequestedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId) loadRequested,
    required TResult Function() deleteRequested,
    required TResult Function() retryProcessing,
    required TResult Function() deleteLocalAudioRequested,
    required TResult Function(StartupAnalysisEditableField field, String value)
    analysisFieldUpdated,
    required TResult Function(String title) titleUpdated,
    required TResult Function(AudioNote note) noteUpdated,
  }) {
    return deleteLocalAudioRequested();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId)? loadRequested,
    TResult? Function()? deleteRequested,
    TResult? Function()? retryProcessing,
    TResult? Function()? deleteLocalAudioRequested,
    TResult? Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult? Function(String title)? titleUpdated,
    TResult? Function(AudioNote note)? noteUpdated,
  }) {
    return deleteLocalAudioRequested?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId)? loadRequested,
    TResult Function()? deleteRequested,
    TResult Function()? retryProcessing,
    TResult Function()? deleteLocalAudioRequested,
    TResult Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult Function(String title)? titleUpdated,
    TResult Function(AudioNote note)? noteUpdated,
    required TResult orElse(),
  }) {
    if (deleteLocalAudioRequested != null) {
      return deleteLocalAudioRequested();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadRequested value) loadRequested,
    required TResult Function(_DeleteRequested value) deleteRequested,
    required TResult Function(_RetryProcessing value) retryProcessing,
    required TResult Function(_DeleteLocalAudioRequested value)
    deleteLocalAudioRequested,
    required TResult Function(_AnalysisFieldUpdated value) analysisFieldUpdated,
    required TResult Function(_TitleUpdated value) titleUpdated,
    required TResult Function(_NoteUpdated value) noteUpdated,
  }) {
    return deleteLocalAudioRequested(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadRequested value)? loadRequested,
    TResult? Function(_DeleteRequested value)? deleteRequested,
    TResult? Function(_RetryProcessing value)? retryProcessing,
    TResult? Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult? Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult? Function(_TitleUpdated value)? titleUpdated,
    TResult? Function(_NoteUpdated value)? noteUpdated,
  }) {
    return deleteLocalAudioRequested?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadRequested value)? loadRequested,
    TResult Function(_DeleteRequested value)? deleteRequested,
    TResult Function(_RetryProcessing value)? retryProcessing,
    TResult Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult Function(_TitleUpdated value)? titleUpdated,
    TResult Function(_NoteUpdated value)? noteUpdated,
    required TResult orElse(),
  }) {
    if (deleteLocalAudioRequested != null) {
      return deleteLocalAudioRequested(this);
    }
    return orElse();
  }
}

abstract class _DeleteLocalAudioRequested implements NoteDetailEvent {
  const factory _DeleteLocalAudioRequested() = _$DeleteLocalAudioRequestedImpl;
}

/// @nodoc
abstract class _$$AnalysisFieldUpdatedImplCopyWith<$Res> {
  factory _$$AnalysisFieldUpdatedImplCopyWith(
    _$AnalysisFieldUpdatedImpl value,
    $Res Function(_$AnalysisFieldUpdatedImpl) then,
  ) = __$$AnalysisFieldUpdatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({StartupAnalysisEditableField field, String value});
}

/// @nodoc
class __$$AnalysisFieldUpdatedImplCopyWithImpl<$Res>
    extends _$NoteDetailEventCopyWithImpl<$Res, _$AnalysisFieldUpdatedImpl>
    implements _$$AnalysisFieldUpdatedImplCopyWith<$Res> {
  __$$AnalysisFieldUpdatedImplCopyWithImpl(
    _$AnalysisFieldUpdatedImpl _value,
    $Res Function(_$AnalysisFieldUpdatedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? field = null, Object? value = null}) {
    return _then(
      _$AnalysisFieldUpdatedImpl(
        field: null == field
            ? _value.field
            : field // ignore: cast_nullable_to_non_nullable
                  as StartupAnalysisEditableField,
        value: null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AnalysisFieldUpdatedImpl implements _AnalysisFieldUpdated {
  const _$AnalysisFieldUpdatedImpl({required this.field, required this.value});

  @override
  final StartupAnalysisEditableField field;
  @override
  final String value;

  @override
  String toString() {
    return 'NoteDetailEvent.analysisFieldUpdated(field: $field, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalysisFieldUpdatedImpl &&
            (identical(other.field, field) || other.field == field) &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, field, value);

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalysisFieldUpdatedImplCopyWith<_$AnalysisFieldUpdatedImpl>
  get copyWith =>
      __$$AnalysisFieldUpdatedImplCopyWithImpl<_$AnalysisFieldUpdatedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId) loadRequested,
    required TResult Function() deleteRequested,
    required TResult Function() retryProcessing,
    required TResult Function() deleteLocalAudioRequested,
    required TResult Function(StartupAnalysisEditableField field, String value)
    analysisFieldUpdated,
    required TResult Function(String title) titleUpdated,
    required TResult Function(AudioNote note) noteUpdated,
  }) {
    return analysisFieldUpdated(field, value);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId)? loadRequested,
    TResult? Function()? deleteRequested,
    TResult? Function()? retryProcessing,
    TResult? Function()? deleteLocalAudioRequested,
    TResult? Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult? Function(String title)? titleUpdated,
    TResult? Function(AudioNote note)? noteUpdated,
  }) {
    return analysisFieldUpdated?.call(field, value);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId)? loadRequested,
    TResult Function()? deleteRequested,
    TResult Function()? retryProcessing,
    TResult Function()? deleteLocalAudioRequested,
    TResult Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult Function(String title)? titleUpdated,
    TResult Function(AudioNote note)? noteUpdated,
    required TResult orElse(),
  }) {
    if (analysisFieldUpdated != null) {
      return analysisFieldUpdated(field, value);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadRequested value) loadRequested,
    required TResult Function(_DeleteRequested value) deleteRequested,
    required TResult Function(_RetryProcessing value) retryProcessing,
    required TResult Function(_DeleteLocalAudioRequested value)
    deleteLocalAudioRequested,
    required TResult Function(_AnalysisFieldUpdated value) analysisFieldUpdated,
    required TResult Function(_TitleUpdated value) titleUpdated,
    required TResult Function(_NoteUpdated value) noteUpdated,
  }) {
    return analysisFieldUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadRequested value)? loadRequested,
    TResult? Function(_DeleteRequested value)? deleteRequested,
    TResult? Function(_RetryProcessing value)? retryProcessing,
    TResult? Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult? Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult? Function(_TitleUpdated value)? titleUpdated,
    TResult? Function(_NoteUpdated value)? noteUpdated,
  }) {
    return analysisFieldUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadRequested value)? loadRequested,
    TResult Function(_DeleteRequested value)? deleteRequested,
    TResult Function(_RetryProcessing value)? retryProcessing,
    TResult Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult Function(_TitleUpdated value)? titleUpdated,
    TResult Function(_NoteUpdated value)? noteUpdated,
    required TResult orElse(),
  }) {
    if (analysisFieldUpdated != null) {
      return analysisFieldUpdated(this);
    }
    return orElse();
  }
}

abstract class _AnalysisFieldUpdated implements NoteDetailEvent {
  const factory _AnalysisFieldUpdated({
    required final StartupAnalysisEditableField field,
    required final String value,
  }) = _$AnalysisFieldUpdatedImpl;

  StartupAnalysisEditableField get field;
  String get value;

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnalysisFieldUpdatedImplCopyWith<_$AnalysisFieldUpdatedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TitleUpdatedImplCopyWith<$Res> {
  factory _$$TitleUpdatedImplCopyWith(
    _$TitleUpdatedImpl value,
    $Res Function(_$TitleUpdatedImpl) then,
  ) = __$$TitleUpdatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String title});
}

/// @nodoc
class __$$TitleUpdatedImplCopyWithImpl<$Res>
    extends _$NoteDetailEventCopyWithImpl<$Res, _$TitleUpdatedImpl>
    implements _$$TitleUpdatedImplCopyWith<$Res> {
  __$$TitleUpdatedImplCopyWithImpl(
    _$TitleUpdatedImpl _value,
    $Res Function(_$TitleUpdatedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? title = null}) {
    return _then(
      _$TitleUpdatedImpl(
        null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$TitleUpdatedImpl implements _TitleUpdated {
  const _$TitleUpdatedImpl(this.title);

  @override
  final String title;

  @override
  String toString() {
    return 'NoteDetailEvent.titleUpdated(title: $title)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TitleUpdatedImpl &&
            (identical(other.title, title) || other.title == title));
  }

  @override
  int get hashCode => Object.hash(runtimeType, title);

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TitleUpdatedImplCopyWith<_$TitleUpdatedImpl> get copyWith =>
      __$$TitleUpdatedImplCopyWithImpl<_$TitleUpdatedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId) loadRequested,
    required TResult Function() deleteRequested,
    required TResult Function() retryProcessing,
    required TResult Function() deleteLocalAudioRequested,
    required TResult Function(StartupAnalysisEditableField field, String value)
    analysisFieldUpdated,
    required TResult Function(String title) titleUpdated,
    required TResult Function(AudioNote note) noteUpdated,
  }) {
    return titleUpdated(title);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId)? loadRequested,
    TResult? Function()? deleteRequested,
    TResult? Function()? retryProcessing,
    TResult? Function()? deleteLocalAudioRequested,
    TResult? Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult? Function(String title)? titleUpdated,
    TResult? Function(AudioNote note)? noteUpdated,
  }) {
    return titleUpdated?.call(title);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId)? loadRequested,
    TResult Function()? deleteRequested,
    TResult Function()? retryProcessing,
    TResult Function()? deleteLocalAudioRequested,
    TResult Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult Function(String title)? titleUpdated,
    TResult Function(AudioNote note)? noteUpdated,
    required TResult orElse(),
  }) {
    if (titleUpdated != null) {
      return titleUpdated(title);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadRequested value) loadRequested,
    required TResult Function(_DeleteRequested value) deleteRequested,
    required TResult Function(_RetryProcessing value) retryProcessing,
    required TResult Function(_DeleteLocalAudioRequested value)
    deleteLocalAudioRequested,
    required TResult Function(_AnalysisFieldUpdated value) analysisFieldUpdated,
    required TResult Function(_TitleUpdated value) titleUpdated,
    required TResult Function(_NoteUpdated value) noteUpdated,
  }) {
    return titleUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadRequested value)? loadRequested,
    TResult? Function(_DeleteRequested value)? deleteRequested,
    TResult? Function(_RetryProcessing value)? retryProcessing,
    TResult? Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult? Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult? Function(_TitleUpdated value)? titleUpdated,
    TResult? Function(_NoteUpdated value)? noteUpdated,
  }) {
    return titleUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadRequested value)? loadRequested,
    TResult Function(_DeleteRequested value)? deleteRequested,
    TResult Function(_RetryProcessing value)? retryProcessing,
    TResult Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult Function(_TitleUpdated value)? titleUpdated,
    TResult Function(_NoteUpdated value)? noteUpdated,
    required TResult orElse(),
  }) {
    if (titleUpdated != null) {
      return titleUpdated(this);
    }
    return orElse();
  }
}

abstract class _TitleUpdated implements NoteDetailEvent {
  const factory _TitleUpdated(final String title) = _$TitleUpdatedImpl;

  String get title;

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TitleUpdatedImplCopyWith<_$TitleUpdatedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NoteUpdatedImplCopyWith<$Res> {
  factory _$$NoteUpdatedImplCopyWith(
    _$NoteUpdatedImpl value,
    $Res Function(_$NoteUpdatedImpl) then,
  ) = __$$NoteUpdatedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({AudioNote note});
}

/// @nodoc
class __$$NoteUpdatedImplCopyWithImpl<$Res>
    extends _$NoteDetailEventCopyWithImpl<$Res, _$NoteUpdatedImpl>
    implements _$$NoteUpdatedImplCopyWith<$Res> {
  __$$NoteUpdatedImplCopyWithImpl(
    _$NoteUpdatedImpl _value,
    $Res Function(_$NoteUpdatedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? note = null}) {
    return _then(
      _$NoteUpdatedImpl(
        null == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as AudioNote,
      ),
    );
  }
}

/// @nodoc

class _$NoteUpdatedImpl implements _NoteUpdated {
  const _$NoteUpdatedImpl(this.note);

  @override
  final AudioNote note;

  @override
  String toString() {
    return 'NoteDetailEvent.noteUpdated(note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NoteUpdatedImpl &&
            (identical(other.note, note) || other.note == note));
  }

  @override
  int get hashCode => Object.hash(runtimeType, note);

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NoteUpdatedImplCopyWith<_$NoteUpdatedImpl> get copyWith =>
      __$$NoteUpdatedImplCopyWithImpl<_$NoteUpdatedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String noteId) loadRequested,
    required TResult Function() deleteRequested,
    required TResult Function() retryProcessing,
    required TResult Function() deleteLocalAudioRequested,
    required TResult Function(StartupAnalysisEditableField field, String value)
    analysisFieldUpdated,
    required TResult Function(String title) titleUpdated,
    required TResult Function(AudioNote note) noteUpdated,
  }) {
    return noteUpdated(note);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String noteId)? loadRequested,
    TResult? Function()? deleteRequested,
    TResult? Function()? retryProcessing,
    TResult? Function()? deleteLocalAudioRequested,
    TResult? Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult? Function(String title)? titleUpdated,
    TResult? Function(AudioNote note)? noteUpdated,
  }) {
    return noteUpdated?.call(note);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String noteId)? loadRequested,
    TResult Function()? deleteRequested,
    TResult Function()? retryProcessing,
    TResult Function()? deleteLocalAudioRequested,
    TResult Function(StartupAnalysisEditableField field, String value)?
    analysisFieldUpdated,
    TResult Function(String title)? titleUpdated,
    TResult Function(AudioNote note)? noteUpdated,
    required TResult orElse(),
  }) {
    if (noteUpdated != null) {
      return noteUpdated(note);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadRequested value) loadRequested,
    required TResult Function(_DeleteRequested value) deleteRequested,
    required TResult Function(_RetryProcessing value) retryProcessing,
    required TResult Function(_DeleteLocalAudioRequested value)
    deleteLocalAudioRequested,
    required TResult Function(_AnalysisFieldUpdated value) analysisFieldUpdated,
    required TResult Function(_TitleUpdated value) titleUpdated,
    required TResult Function(_NoteUpdated value) noteUpdated,
  }) {
    return noteUpdated(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadRequested value)? loadRequested,
    TResult? Function(_DeleteRequested value)? deleteRequested,
    TResult? Function(_RetryProcessing value)? retryProcessing,
    TResult? Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult? Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult? Function(_TitleUpdated value)? titleUpdated,
    TResult? Function(_NoteUpdated value)? noteUpdated,
  }) {
    return noteUpdated?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadRequested value)? loadRequested,
    TResult Function(_DeleteRequested value)? deleteRequested,
    TResult Function(_RetryProcessing value)? retryProcessing,
    TResult Function(_DeleteLocalAudioRequested value)?
    deleteLocalAudioRequested,
    TResult Function(_AnalysisFieldUpdated value)? analysisFieldUpdated,
    TResult Function(_TitleUpdated value)? titleUpdated,
    TResult Function(_NoteUpdated value)? noteUpdated,
    required TResult orElse(),
  }) {
    if (noteUpdated != null) {
      return noteUpdated(this);
    }
    return orElse();
  }
}

abstract class _NoteUpdated implements NoteDetailEvent {
  const factory _NoteUpdated(final AudioNote note) = _$NoteUpdatedImpl;

  AudioNote get note;

  /// Create a copy of NoteDetailEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NoteUpdatedImplCopyWith<_$NoteUpdatedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$NoteDetailState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )
    loaded,
    required TResult Function() deleted,
    required TResult Function(String message) failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )?
    loaded,
    TResult? Function()? deleted,
    TResult? Function(String message)? failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )?
    loaded,
    TResult Function()? deleted,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NdInitial value) initial,
    required TResult Function(_NdLoading value) loading,
    required TResult Function(_NdLoaded value) loaded,
    required TResult Function(_NdDeleted value) deleted,
    required TResult Function(_NdFailure value) failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NdInitial value)? initial,
    TResult? Function(_NdLoading value)? loading,
    TResult? Function(_NdLoaded value)? loaded,
    TResult? Function(_NdDeleted value)? deleted,
    TResult? Function(_NdFailure value)? failure,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NdInitial value)? initial,
    TResult Function(_NdLoading value)? loading,
    TResult Function(_NdLoaded value)? loaded,
    TResult Function(_NdDeleted value)? deleted,
    TResult Function(_NdFailure value)? failure,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NoteDetailStateCopyWith<$Res> {
  factory $NoteDetailStateCopyWith(
    NoteDetailState value,
    $Res Function(NoteDetailState) then,
  ) = _$NoteDetailStateCopyWithImpl<$Res, NoteDetailState>;
}

/// @nodoc
class _$NoteDetailStateCopyWithImpl<$Res, $Val extends NoteDetailState>
    implements $NoteDetailStateCopyWith<$Res> {
  _$NoteDetailStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NoteDetailState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$NdInitialImplCopyWith<$Res> {
  factory _$$NdInitialImplCopyWith(
    _$NdInitialImpl value,
    $Res Function(_$NdInitialImpl) then,
  ) = __$$NdInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NdInitialImplCopyWithImpl<$Res>
    extends _$NoteDetailStateCopyWithImpl<$Res, _$NdInitialImpl>
    implements _$$NdInitialImplCopyWith<$Res> {
  __$$NdInitialImplCopyWithImpl(
    _$NdInitialImpl _value,
    $Res Function(_$NdInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteDetailState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NdInitialImpl implements _NdInitial {
  const _$NdInitialImpl();

  @override
  String toString() {
    return 'NoteDetailState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NdInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )
    loaded,
    required TResult Function() deleted,
    required TResult Function(String message) failure,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )?
    loaded,
    TResult? Function()? deleted,
    TResult? Function(String message)? failure,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )?
    loaded,
    TResult Function()? deleted,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NdInitial value) initial,
    required TResult Function(_NdLoading value) loading,
    required TResult Function(_NdLoaded value) loaded,
    required TResult Function(_NdDeleted value) deleted,
    required TResult Function(_NdFailure value) failure,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NdInitial value)? initial,
    TResult? Function(_NdLoading value)? loading,
    TResult? Function(_NdLoaded value)? loaded,
    TResult? Function(_NdDeleted value)? deleted,
    TResult? Function(_NdFailure value)? failure,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NdInitial value)? initial,
    TResult Function(_NdLoading value)? loading,
    TResult Function(_NdLoaded value)? loaded,
    TResult Function(_NdDeleted value)? deleted,
    TResult Function(_NdFailure value)? failure,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _NdInitial implements NoteDetailState {
  const factory _NdInitial() = _$NdInitialImpl;
}

/// @nodoc
abstract class _$$NdLoadingImplCopyWith<$Res> {
  factory _$$NdLoadingImplCopyWith(
    _$NdLoadingImpl value,
    $Res Function(_$NdLoadingImpl) then,
  ) = __$$NdLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NdLoadingImplCopyWithImpl<$Res>
    extends _$NoteDetailStateCopyWithImpl<$Res, _$NdLoadingImpl>
    implements _$$NdLoadingImplCopyWith<$Res> {
  __$$NdLoadingImplCopyWithImpl(
    _$NdLoadingImpl _value,
    $Res Function(_$NdLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteDetailState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NdLoadingImpl implements _NdLoading {
  const _$NdLoadingImpl();

  @override
  String toString() {
    return 'NoteDetailState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NdLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )
    loaded,
    required TResult Function() deleted,
    required TResult Function(String message) failure,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )?
    loaded,
    TResult? Function()? deleted,
    TResult? Function(String message)? failure,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )?
    loaded,
    TResult Function()? deleted,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NdInitial value) initial,
    required TResult Function(_NdLoading value) loading,
    required TResult Function(_NdLoaded value) loaded,
    required TResult Function(_NdDeleted value) deleted,
    required TResult Function(_NdFailure value) failure,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NdInitial value)? initial,
    TResult? Function(_NdLoading value)? loading,
    TResult? Function(_NdLoaded value)? loaded,
    TResult? Function(_NdDeleted value)? deleted,
    TResult? Function(_NdFailure value)? failure,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NdInitial value)? initial,
    TResult Function(_NdLoading value)? loading,
    TResult Function(_NdLoaded value)? loaded,
    TResult Function(_NdDeleted value)? deleted,
    TResult Function(_NdFailure value)? failure,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _NdLoading implements NoteDetailState {
  const factory _NdLoading() = _$NdLoadingImpl;
}

/// @nodoc
abstract class _$$NdLoadedImplCopyWith<$Res> {
  factory _$$NdLoadedImplCopyWith(
    _$NdLoadedImpl value,
    $Res Function(_$NdLoadedImpl) then,
  ) = __$$NdLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    AudioNote note,
    AudioNoteTranscript? transcript,
    StartupAnalysis? analysis,
    bool localAudioExists,
  });
}

/// @nodoc
class __$$NdLoadedImplCopyWithImpl<$Res>
    extends _$NoteDetailStateCopyWithImpl<$Res, _$NdLoadedImpl>
    implements _$$NdLoadedImplCopyWith<$Res> {
  __$$NdLoadedImplCopyWithImpl(
    _$NdLoadedImpl _value,
    $Res Function(_$NdLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteDetailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? note = null,
    Object? transcript = freezed,
    Object? analysis = freezed,
    Object? localAudioExists = null,
  }) {
    return _then(
      _$NdLoadedImpl(
        note: null == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as AudioNote,
        transcript: freezed == transcript
            ? _value.transcript
            : transcript // ignore: cast_nullable_to_non_nullable
                  as AudioNoteTranscript?,
        analysis: freezed == analysis
            ? _value.analysis
            : analysis // ignore: cast_nullable_to_non_nullable
                  as StartupAnalysis?,
        localAudioExists: null == localAudioExists
            ? _value.localAudioExists
            : localAudioExists // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$NdLoadedImpl implements _NdLoaded {
  const _$NdLoadedImpl({
    required this.note,
    this.transcript,
    this.analysis,
    required this.localAudioExists,
  });

  @override
  final AudioNote note;
  @override
  final AudioNoteTranscript? transcript;
  @override
  final StartupAnalysis? analysis;
  @override
  final bool localAudioExists;

  @override
  String toString() {
    return 'NoteDetailState.loaded(note: $note, transcript: $transcript, analysis: $analysis, localAudioExists: $localAudioExists)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NdLoadedImpl &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.transcript, transcript) ||
                other.transcript == transcript) &&
            (identical(other.analysis, analysis) ||
                other.analysis == analysis) &&
            (identical(other.localAudioExists, localAudioExists) ||
                other.localAudioExists == localAudioExists));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, note, transcript, analysis, localAudioExists);

  /// Create a copy of NoteDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NdLoadedImplCopyWith<_$NdLoadedImpl> get copyWith =>
      __$$NdLoadedImplCopyWithImpl<_$NdLoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )
    loaded,
    required TResult Function() deleted,
    required TResult Function(String message) failure,
  }) {
    return loaded(note, transcript, analysis, localAudioExists);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )?
    loaded,
    TResult? Function()? deleted,
    TResult? Function(String message)? failure,
  }) {
    return loaded?.call(note, transcript, analysis, localAudioExists);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )?
    loaded,
    TResult Function()? deleted,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(note, transcript, analysis, localAudioExists);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NdInitial value) initial,
    required TResult Function(_NdLoading value) loading,
    required TResult Function(_NdLoaded value) loaded,
    required TResult Function(_NdDeleted value) deleted,
    required TResult Function(_NdFailure value) failure,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NdInitial value)? initial,
    TResult? Function(_NdLoading value)? loading,
    TResult? Function(_NdLoaded value)? loaded,
    TResult? Function(_NdDeleted value)? deleted,
    TResult? Function(_NdFailure value)? failure,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NdInitial value)? initial,
    TResult Function(_NdLoading value)? loading,
    TResult Function(_NdLoaded value)? loaded,
    TResult Function(_NdDeleted value)? deleted,
    TResult Function(_NdFailure value)? failure,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _NdLoaded implements NoteDetailState {
  const factory _NdLoaded({
    required final AudioNote note,
    final AudioNoteTranscript? transcript,
    final StartupAnalysis? analysis,
    required final bool localAudioExists,
  }) = _$NdLoadedImpl;

  AudioNote get note;
  AudioNoteTranscript? get transcript;
  StartupAnalysis? get analysis;
  bool get localAudioExists;

  /// Create a copy of NoteDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NdLoadedImplCopyWith<_$NdLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$NdDeletedImplCopyWith<$Res> {
  factory _$$NdDeletedImplCopyWith(
    _$NdDeletedImpl value,
    $Res Function(_$NdDeletedImpl) then,
  ) = __$$NdDeletedImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NdDeletedImplCopyWithImpl<$Res>
    extends _$NoteDetailStateCopyWithImpl<$Res, _$NdDeletedImpl>
    implements _$$NdDeletedImplCopyWith<$Res> {
  __$$NdDeletedImplCopyWithImpl(
    _$NdDeletedImpl _value,
    $Res Function(_$NdDeletedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteDetailState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$NdDeletedImpl implements _NdDeleted {
  const _$NdDeletedImpl();

  @override
  String toString() {
    return 'NoteDetailState.deleted()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NdDeletedImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )
    loaded,
    required TResult Function() deleted,
    required TResult Function(String message) failure,
  }) {
    return deleted();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )?
    loaded,
    TResult? Function()? deleted,
    TResult? Function(String message)? failure,
  }) {
    return deleted?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )?
    loaded,
    TResult Function()? deleted,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (deleted != null) {
      return deleted();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NdInitial value) initial,
    required TResult Function(_NdLoading value) loading,
    required TResult Function(_NdLoaded value) loaded,
    required TResult Function(_NdDeleted value) deleted,
    required TResult Function(_NdFailure value) failure,
  }) {
    return deleted(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NdInitial value)? initial,
    TResult? Function(_NdLoading value)? loading,
    TResult? Function(_NdLoaded value)? loaded,
    TResult? Function(_NdDeleted value)? deleted,
    TResult? Function(_NdFailure value)? failure,
  }) {
    return deleted?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NdInitial value)? initial,
    TResult Function(_NdLoading value)? loading,
    TResult Function(_NdLoaded value)? loaded,
    TResult Function(_NdDeleted value)? deleted,
    TResult Function(_NdFailure value)? failure,
    required TResult orElse(),
  }) {
    if (deleted != null) {
      return deleted(this);
    }
    return orElse();
  }
}

abstract class _NdDeleted implements NoteDetailState {
  const factory _NdDeleted() = _$NdDeletedImpl;
}

/// @nodoc
abstract class _$$NdFailureImplCopyWith<$Res> {
  factory _$$NdFailureImplCopyWith(
    _$NdFailureImpl value,
    $Res Function(_$NdFailureImpl) then,
  ) = __$$NdFailureImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$NdFailureImplCopyWithImpl<$Res>
    extends _$NoteDetailStateCopyWithImpl<$Res, _$NdFailureImpl>
    implements _$$NdFailureImplCopyWith<$Res> {
  __$$NdFailureImplCopyWithImpl(
    _$NdFailureImpl _value,
    $Res Function(_$NdFailureImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of NoteDetailState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$NdFailureImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$NdFailureImpl implements _NdFailure {
  const _$NdFailureImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'NoteDetailState.failure(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NdFailureImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of NoteDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NdFailureImplCopyWith<_$NdFailureImpl> get copyWith =>
      __$$NdFailureImplCopyWithImpl<_$NdFailureImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )
    loaded,
    required TResult Function() deleted,
    required TResult Function(String message) failure,
  }) {
    return failure(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )?
    loaded,
    TResult? Function()? deleted,
    TResult? Function(String message)? failure,
  }) {
    return failure?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      AudioNote note,
      AudioNoteTranscript? transcript,
      StartupAnalysis? analysis,
      bool localAudioExists,
    )?
    loaded,
    TResult Function()? deleted,
    TResult Function(String message)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_NdInitial value) initial,
    required TResult Function(_NdLoading value) loading,
    required TResult Function(_NdLoaded value) loaded,
    required TResult Function(_NdDeleted value) deleted,
    required TResult Function(_NdFailure value) failure,
  }) {
    return failure(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_NdInitial value)? initial,
    TResult? Function(_NdLoading value)? loading,
    TResult? Function(_NdLoaded value)? loaded,
    TResult? Function(_NdDeleted value)? deleted,
    TResult? Function(_NdFailure value)? failure,
  }) {
    return failure?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_NdInitial value)? initial,
    TResult Function(_NdLoading value)? loading,
    TResult Function(_NdLoaded value)? loaded,
    TResult Function(_NdDeleted value)? deleted,
    TResult Function(_NdFailure value)? failure,
    required TResult orElse(),
  }) {
    if (failure != null) {
      return failure(this);
    }
    return orElse();
  }
}

abstract class _NdFailure implements NoteDetailState {
  const factory _NdFailure(final String message) = _$NdFailureImpl;

  String get message;

  /// Create a copy of NoteDetailState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NdFailureImplCopyWith<_$NdFailureImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
