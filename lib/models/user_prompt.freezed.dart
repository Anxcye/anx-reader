// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_prompt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserPrompt {
  String get id; // ID generated from millisecondsSinceEpoch
  String get name; // Prompt name
  String get content; // Prompt content
  bool get enabled; // Whether the prompt is enabled
  int get order; // Display order
  DateTime get createdAt; // Creation time
  DateTime get updatedAt;

  /// Create a copy of UserPrompt
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UserPromptCopyWith<UserPrompt> get copyWith =>
      _$UserPromptCopyWithImpl<UserPrompt>(this as UserPrompt, _$identity);

  /// Serializes this UserPrompt to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UserPrompt &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, content, enabled, order, createdAt, updatedAt);

  @override
  String toString() {
    return 'UserPrompt(id: $id, name: $name, content: $content, enabled: $enabled, order: $order, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $UserPromptCopyWith<$Res> {
  factory $UserPromptCopyWith(
          UserPrompt value, $Res Function(UserPrompt) _then) =
      _$UserPromptCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String content,
      bool enabled,
      int order,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$UserPromptCopyWithImpl<$Res> implements $UserPromptCopyWith<$Res> {
  _$UserPromptCopyWithImpl(this._self, this._then);

  final UserPrompt _self;
  final $Res Function(UserPrompt) _then;

  /// Create a copy of UserPrompt
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? content = null,
    Object? enabled = null,
    Object? order = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      order: null == order
          ? _self.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _UserPrompt extends UserPrompt {
  const _UserPrompt(
      {required this.id,
      required this.name,
      required this.content,
      this.enabled = true,
      required this.order,
      required this.createdAt,
      required this.updatedAt})
      : super._();
  factory _UserPrompt.fromJson(Map<String, dynamic> json) =>
      _$UserPromptFromJson(json);

  @override
  final String id;
// ID generated from millisecondsSinceEpoch
  @override
  final String name;
// Prompt name
  @override
  final String content;
// Prompt content
  @override
  @JsonKey()
  final bool enabled;
// Whether the prompt is enabled
  @override
  final int order;
// Display order
  @override
  final DateTime createdAt;
// Creation time
  @override
  final DateTime updatedAt;

  /// Create a copy of UserPrompt
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UserPromptCopyWith<_UserPrompt> get copyWith =>
      __$UserPromptCopyWithImpl<_UserPrompt>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UserPromptToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UserPrompt &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, content, enabled, order, createdAt, updatedAt);

  @override
  String toString() {
    return 'UserPrompt(id: $id, name: $name, content: $content, enabled: $enabled, order: $order, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$UserPromptCopyWith<$Res>
    implements $UserPromptCopyWith<$Res> {
  factory _$UserPromptCopyWith(
          _UserPrompt value, $Res Function(_UserPrompt) _then) =
      __$UserPromptCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String content,
      bool enabled,
      int order,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$UserPromptCopyWithImpl<$Res> implements _$UserPromptCopyWith<$Res> {
  __$UserPromptCopyWithImpl(this._self, this._then);

  final _UserPrompt _self;
  final $Res Function(_UserPrompt) _then;

  /// Create a copy of UserPrompt
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? content = null,
    Object? enabled = null,
    Object? order = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_UserPrompt(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      order: null == order
          ? _self.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
