// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chapter_content_by_href_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChapterContentByHrefInput {
  String get href;
  int? get maxCharacters;

  /// Create a copy of ChapterContentByHrefInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ChapterContentByHrefInputCopyWith<ChapterContentByHrefInput> get copyWith =>
      _$ChapterContentByHrefInputCopyWithImpl<ChapterContentByHrefInput>(
          this as ChapterContentByHrefInput, _$identity);

  /// Serializes this ChapterContentByHrefInput to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ChapterContentByHrefInput &&
            (identical(other.href, href) || other.href == href) &&
            (identical(other.maxCharacters, maxCharacters) ||
                other.maxCharacters == maxCharacters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, href, maxCharacters);

  @override
  String toString() {
    return 'ChapterContentByHrefInput(href: $href, maxCharacters: $maxCharacters)';
  }
}

/// @nodoc
abstract mixin class $ChapterContentByHrefInputCopyWith<$Res> {
  factory $ChapterContentByHrefInputCopyWith(ChapterContentByHrefInput value,
          $Res Function(ChapterContentByHrefInput) _then) =
      _$ChapterContentByHrefInputCopyWithImpl;
  @useResult
  $Res call({String href, int? maxCharacters});
}

/// @nodoc
class _$ChapterContentByHrefInputCopyWithImpl<$Res>
    implements $ChapterContentByHrefInputCopyWith<$Res> {
  _$ChapterContentByHrefInputCopyWithImpl(this._self, this._then);

  final ChapterContentByHrefInput _self;
  final $Res Function(ChapterContentByHrefInput) _then;

  /// Create a copy of ChapterContentByHrefInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? href = null,
    Object? maxCharacters = freezed,
  }) {
    return _then(_self.copyWith(
      href: null == href
          ? _self.href
          : href // ignore: cast_nullable_to_non_nullable
              as String,
      maxCharacters: freezed == maxCharacters
          ? _self.maxCharacters
          : maxCharacters // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ChapterContentByHrefInput implements ChapterContentByHrefInput {
  _ChapterContentByHrefInput({required this.href, this.maxCharacters});
  factory _ChapterContentByHrefInput.fromJson(Map<String, dynamic> json) =>
      _$ChapterContentByHrefInputFromJson(json);

  @override
  final String href;
  @override
  final int? maxCharacters;

  /// Create a copy of ChapterContentByHrefInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ChapterContentByHrefInputCopyWith<_ChapterContentByHrefInput>
      get copyWith =>
          __$ChapterContentByHrefInputCopyWithImpl<_ChapterContentByHrefInput>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ChapterContentByHrefInputToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ChapterContentByHrefInput &&
            (identical(other.href, href) || other.href == href) &&
            (identical(other.maxCharacters, maxCharacters) ||
                other.maxCharacters == maxCharacters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, href, maxCharacters);

  @override
  String toString() {
    return 'ChapterContentByHrefInput(href: $href, maxCharacters: $maxCharacters)';
  }
}

/// @nodoc
abstract mixin class _$ChapterContentByHrefInputCopyWith<$Res>
    implements $ChapterContentByHrefInputCopyWith<$Res> {
  factory _$ChapterContentByHrefInputCopyWith(_ChapterContentByHrefInput value,
          $Res Function(_ChapterContentByHrefInput) _then) =
      __$ChapterContentByHrefInputCopyWithImpl;
  @override
  @useResult
  $Res call({String href, int? maxCharacters});
}

/// @nodoc
class __$ChapterContentByHrefInputCopyWithImpl<$Res>
    implements _$ChapterContentByHrefInputCopyWith<$Res> {
  __$ChapterContentByHrefInputCopyWithImpl(this._self, this._then);

  final _ChapterContentByHrefInput _self;
  final $Res Function(_ChapterContentByHrefInput) _then;

  /// Create a copy of ChapterContentByHrefInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? href = null,
    Object? maxCharacters = freezed,
  }) {
    return _then(_ChapterContentByHrefInput(
      href: null == href
          ? _self.href
          : href // ignore: cast_nullable_to_non_nullable
              as String,
      maxCharacters: freezed == maxCharacters
          ? _self.maxCharacters
          : maxCharacters // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
