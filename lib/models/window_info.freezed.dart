// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'window_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WindowInfo {
  double get x;
  double get y;
  double get width;
  double get height;
  bool get isMaximized;

  /// Create a copy of WindowInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WindowInfoCopyWith<WindowInfo> get copyWith =>
      _$WindowInfoCopyWithImpl<WindowInfo>(this as WindowInfo, _$identity);

  /// Serializes this WindowInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WindowInfo &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.isMaximized, isMaximized) ||
                other.isMaximized == isMaximized));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, x, y, width, height, isMaximized);

  @override
  String toString() {
    return 'WindowInfo(x: $x, y: $y, width: $width, height: $height, isMaximized: $isMaximized)';
  }
}

/// @nodoc
abstract mixin class $WindowInfoCopyWith<$Res> {
  factory $WindowInfoCopyWith(
          WindowInfo value, $Res Function(WindowInfo) _then) =
      _$WindowInfoCopyWithImpl;
  @useResult
  $Res call(
      {double x, double y, double width, double height, bool isMaximized});
}

/// @nodoc
class _$WindowInfoCopyWithImpl<$Res> implements $WindowInfoCopyWith<$Res> {
  _$WindowInfoCopyWithImpl(this._self, this._then);

  final WindowInfo _self;
  final $Res Function(WindowInfo) _then;

  /// Create a copy of WindowInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
    Object? isMaximized = null,
  }) {
    return _then(_self.copyWith(
      x: null == x
          ? _self.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _self.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      isMaximized: null == isMaximized
          ? _self.isMaximized
          : isMaximized // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _WindowInfo implements WindowInfo {
  const _WindowInfo(
      {required this.x,
      required this.y,
      required this.width,
      required this.height,
      this.isMaximized = false});
  factory _WindowInfo.fromJson(Map<String, dynamic> json) =>
      _$WindowInfoFromJson(json);

  @override
  final double x;
  @override
  final double y;
  @override
  final double width;
  @override
  final double height;
  @override
  @JsonKey()
  final bool isMaximized;

  /// Create a copy of WindowInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WindowInfoCopyWith<_WindowInfo> get copyWith =>
      __$WindowInfoCopyWithImpl<_WindowInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WindowInfoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WindowInfo &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.isMaximized, isMaximized) ||
                other.isMaximized == isMaximized));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, x, y, width, height, isMaximized);

  @override
  String toString() {
    return 'WindowInfo(x: $x, y: $y, width: $width, height: $height, isMaximized: $isMaximized)';
  }
}

/// @nodoc
abstract mixin class _$WindowInfoCopyWith<$Res>
    implements $WindowInfoCopyWith<$Res> {
  factory _$WindowInfoCopyWith(
          _WindowInfo value, $Res Function(_WindowInfo) _then) =
      __$WindowInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double x, double y, double width, double height, bool isMaximized});
}

/// @nodoc
class __$WindowInfoCopyWithImpl<$Res> implements _$WindowInfoCopyWith<$Res> {
  __$WindowInfoCopyWithImpl(this._self, this._then);

  final _WindowInfo _self;
  final $Res Function(_WindowInfo) _then;

  /// Create a copy of WindowInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
    Object? isMaximized = null,
  }) {
    return _then(_WindowInfo(
      x: null == x
          ? _self.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _self.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _self.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _self.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      isMaximized: null == isMaximized
          ? _self.isMaximized
          : isMaximized // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
