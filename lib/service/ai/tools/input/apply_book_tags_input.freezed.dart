// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'apply_book_tags_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApplyBookTagsInput {
  List<BookTagRequest> get books;
  List<CreateTagRequest> get createTags;
  List<UpdateTagRequest> get updateTags;

  /// Create a copy of ApplyBookTagsInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ApplyBookTagsInputCopyWith<ApplyBookTagsInput> get copyWith =>
      _$ApplyBookTagsInputCopyWithImpl<ApplyBookTagsInput>(
          this as ApplyBookTagsInput, _$identity);

  /// Serializes this ApplyBookTagsInput to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ApplyBookTagsInput &&
            const DeepCollectionEquality().equals(other.books, books) &&
            const DeepCollectionEquality()
                .equals(other.createTags, createTags) &&
            const DeepCollectionEquality()
                .equals(other.updateTags, updateTags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(books),
      const DeepCollectionEquality().hash(createTags),
      const DeepCollectionEquality().hash(updateTags));

  @override
  String toString() {
    return 'ApplyBookTagsInput(books: $books, createTags: $createTags, updateTags: $updateTags)';
  }
}

/// @nodoc
abstract mixin class $ApplyBookTagsInputCopyWith<$Res> {
  factory $ApplyBookTagsInputCopyWith(
          ApplyBookTagsInput value, $Res Function(ApplyBookTagsInput) _then) =
      _$ApplyBookTagsInputCopyWithImpl;
  @useResult
  $Res call(
      {List<BookTagRequest> books,
      List<CreateTagRequest> createTags,
      List<UpdateTagRequest> updateTags});
}

/// @nodoc
class _$ApplyBookTagsInputCopyWithImpl<$Res>
    implements $ApplyBookTagsInputCopyWith<$Res> {
  _$ApplyBookTagsInputCopyWithImpl(this._self, this._then);

  final ApplyBookTagsInput _self;
  final $Res Function(ApplyBookTagsInput) _then;

  /// Create a copy of ApplyBookTagsInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? books = null,
    Object? createTags = null,
    Object? updateTags = null,
  }) {
    return _then(_self.copyWith(
      books: null == books
          ? _self.books
          : books // ignore: cast_nullable_to_non_nullable
              as List<BookTagRequest>,
      createTags: null == createTags
          ? _self.createTags
          : createTags // ignore: cast_nullable_to_non_nullable
              as List<CreateTagRequest>,
      updateTags: null == updateTags
          ? _self.updateTags
          : updateTags // ignore: cast_nullable_to_non_nullable
              as List<UpdateTagRequest>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ApplyBookTagsInput implements ApplyBookTagsInput {
  const _ApplyBookTagsInput(
      {final List<BookTagRequest> books = const <BookTagRequest>[],
      final List<CreateTagRequest> createTags = const <CreateTagRequest>[],
      final List<UpdateTagRequest> updateTags = const <UpdateTagRequest>[]})
      : _books = books,
        _createTags = createTags,
        _updateTags = updateTags;
  factory _ApplyBookTagsInput.fromJson(Map<String, dynamic> json) =>
      _$ApplyBookTagsInputFromJson(json);

  final List<BookTagRequest> _books;
  @override
  @JsonKey()
  List<BookTagRequest> get books {
    if (_books is EqualUnmodifiableListView) return _books;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_books);
  }

  final List<CreateTagRequest> _createTags;
  @override
  @JsonKey()
  List<CreateTagRequest> get createTags {
    if (_createTags is EqualUnmodifiableListView) return _createTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_createTags);
  }

  final List<UpdateTagRequest> _updateTags;
  @override
  @JsonKey()
  List<UpdateTagRequest> get updateTags {
    if (_updateTags is EqualUnmodifiableListView) return _updateTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_updateTags);
  }

  /// Create a copy of ApplyBookTagsInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ApplyBookTagsInputCopyWith<_ApplyBookTagsInput> get copyWith =>
      __$ApplyBookTagsInputCopyWithImpl<_ApplyBookTagsInput>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ApplyBookTagsInputToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ApplyBookTagsInput &&
            const DeepCollectionEquality().equals(other._books, _books) &&
            const DeepCollectionEquality()
                .equals(other._createTags, _createTags) &&
            const DeepCollectionEquality()
                .equals(other._updateTags, _updateTags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_books),
      const DeepCollectionEquality().hash(_createTags),
      const DeepCollectionEquality().hash(_updateTags));

  @override
  String toString() {
    return 'ApplyBookTagsInput(books: $books, createTags: $createTags, updateTags: $updateTags)';
  }
}

/// @nodoc
abstract mixin class _$ApplyBookTagsInputCopyWith<$Res>
    implements $ApplyBookTagsInputCopyWith<$Res> {
  factory _$ApplyBookTagsInputCopyWith(
          _ApplyBookTagsInput value, $Res Function(_ApplyBookTagsInput) _then) =
      __$ApplyBookTagsInputCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<BookTagRequest> books,
      List<CreateTagRequest> createTags,
      List<UpdateTagRequest> updateTags});
}

/// @nodoc
class __$ApplyBookTagsInputCopyWithImpl<$Res>
    implements _$ApplyBookTagsInputCopyWith<$Res> {
  __$ApplyBookTagsInputCopyWithImpl(this._self, this._then);

  final _ApplyBookTagsInput _self;
  final $Res Function(_ApplyBookTagsInput) _then;

  /// Create a copy of ApplyBookTagsInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? books = null,
    Object? createTags = null,
    Object? updateTags = null,
  }) {
    return _then(_ApplyBookTagsInput(
      books: null == books
          ? _self._books
          : books // ignore: cast_nullable_to_non_nullable
              as List<BookTagRequest>,
      createTags: null == createTags
          ? _self._createTags
          : createTags // ignore: cast_nullable_to_non_nullable
              as List<CreateTagRequest>,
      updateTags: null == updateTags
          ? _self._updateTags
          : updateTags // ignore: cast_nullable_to_non_nullable
              as List<UpdateTagRequest>,
    ));
  }
}

// dart format on
