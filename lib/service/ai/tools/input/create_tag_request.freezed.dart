// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_tag_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateTagRequest {
  String get name;
  int? get rgb;

  /// Create a copy of CreateTagRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CreateTagRequestCopyWith<CreateTagRequest> get copyWith =>
      _$CreateTagRequestCopyWithImpl<CreateTagRequest>(
          this as CreateTagRequest, _$identity);

  /// Serializes this CreateTagRequest to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CreateTagRequest &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.rgb, rgb) || other.rgb == rgb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, rgb);

  @override
  String toString() {
    return 'CreateTagRequest(name: $name, rgb: $rgb)';
  }
}

/// @nodoc
abstract mixin class $CreateTagRequestCopyWith<$Res> {
  factory $CreateTagRequestCopyWith(
          CreateTagRequest value, $Res Function(CreateTagRequest) _then) =
      _$CreateTagRequestCopyWithImpl;
  @useResult
  $Res call({String name, int? rgb});
}

/// @nodoc
class _$CreateTagRequestCopyWithImpl<$Res>
    implements $CreateTagRequestCopyWith<$Res> {
  _$CreateTagRequestCopyWithImpl(this._self, this._then);

  final CreateTagRequest _self;
  final $Res Function(CreateTagRequest) _then;

  /// Create a copy of CreateTagRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? rgb = freezed,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      rgb: freezed == rgb
          ? _self.rgb
          : rgb // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _CreateTagRequest extends CreateTagRequest {
  const _CreateTagRequest({required this.name, this.rgb}) : super._();
  factory _CreateTagRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTagRequestFromJson(json);

  @override
  final String name;
  @override
  final int? rgb;

  /// Create a copy of CreateTagRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CreateTagRequestCopyWith<_CreateTagRequest> get copyWith =>
      __$CreateTagRequestCopyWithImpl<_CreateTagRequest>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CreateTagRequestToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CreateTagRequest &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.rgb, rgb) || other.rgb == rgb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, rgb);

  @override
  String toString() {
    return 'CreateTagRequest(name: $name, rgb: $rgb)';
  }
}

/// @nodoc
abstract mixin class _$CreateTagRequestCopyWith<$Res>
    implements $CreateTagRequestCopyWith<$Res> {
  factory _$CreateTagRequestCopyWith(
          _CreateTagRequest value, $Res Function(_CreateTagRequest) _then) =
      __$CreateTagRequestCopyWithImpl;
  @override
  @useResult
  $Res call({String name, int? rgb});
}

/// @nodoc
class __$CreateTagRequestCopyWithImpl<$Res>
    implements _$CreateTagRequestCopyWith<$Res> {
  __$CreateTagRequestCopyWithImpl(this._self, this._then);

  final _CreateTagRequest _self;
  final $Res Function(_CreateTagRequest) _then;

  /// Create a copy of CreateTagRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? rgb = freezed,
  }) {
    return _then(_CreateTagRequest(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      rgb: freezed == rgb
          ? _self.rgb
          : rgb // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
