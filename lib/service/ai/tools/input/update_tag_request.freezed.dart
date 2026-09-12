// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_tag_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateTagRequest {
  int get id;
  String? get name;
  int? get rgb;

  /// Create a copy of UpdateTagRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $UpdateTagRequestCopyWith<UpdateTagRequest> get copyWith =>
      _$UpdateTagRequestCopyWithImpl<UpdateTagRequest>(
          this as UpdateTagRequest, _$identity);

  /// Serializes this UpdateTagRequest to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is UpdateTagRequest &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.rgb, rgb) || other.rgb == rgb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, rgb);

  @override
  String toString() {
    return 'UpdateTagRequest(id: $id, name: $name, rgb: $rgb)';
  }
}

/// @nodoc
abstract mixin class $UpdateTagRequestCopyWith<$Res> {
  factory $UpdateTagRequestCopyWith(
          UpdateTagRequest value, $Res Function(UpdateTagRequest) _then) =
      _$UpdateTagRequestCopyWithImpl;
  @useResult
  $Res call({int id, String? name, int? rgb});
}

/// @nodoc
class _$UpdateTagRequestCopyWithImpl<$Res>
    implements $UpdateTagRequestCopyWith<$Res> {
  _$UpdateTagRequestCopyWithImpl(this._self, this._then);

  final UpdateTagRequest _self;
  final $Res Function(UpdateTagRequest) _then;

  /// Create a copy of UpdateTagRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? rgb = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      rgb: freezed == rgb
          ? _self.rgb
          : rgb // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _UpdateTagRequest extends UpdateTagRequest {
  const _UpdateTagRequest({required this.id, this.name, this.rgb}) : super._();
  factory _UpdateTagRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTagRequestFromJson(json);

  @override
  final int id;
  @override
  final String? name;
  @override
  final int? rgb;

  /// Create a copy of UpdateTagRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$UpdateTagRequestCopyWith<_UpdateTagRequest> get copyWith =>
      __$UpdateTagRequestCopyWithImpl<_UpdateTagRequest>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$UpdateTagRequestToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _UpdateTagRequest &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.rgb, rgb) || other.rgb == rgb));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, rgb);

  @override
  String toString() {
    return 'UpdateTagRequest(id: $id, name: $name, rgb: $rgb)';
  }
}

/// @nodoc
abstract mixin class _$UpdateTagRequestCopyWith<$Res>
    implements $UpdateTagRequestCopyWith<$Res> {
  factory _$UpdateTagRequestCopyWith(
          _UpdateTagRequest value, $Res Function(_UpdateTagRequest) _then) =
      __$UpdateTagRequestCopyWithImpl;
  @override
  @useResult
  $Res call({int id, String? name, int? rgb});
}

/// @nodoc
class __$UpdateTagRequestCopyWithImpl<$Res>
    implements _$UpdateTagRequestCopyWith<$Res> {
  __$UpdateTagRequestCopyWithImpl(this._self, this._then);

  final _UpdateTagRequest _self;
  final $Res Function(_UpdateTagRequest) _then;

  /// Create a copy of UpdateTagRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = freezed,
    Object? rgb = freezed,
  }) {
    return _then(_UpdateTagRequest(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      rgb: freezed == rgb
          ? _self.rgb
          : rgb // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
