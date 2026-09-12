// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bgimg.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BgimgModel {
  BgimgType get type;
  String get path;
  String? get nightPath;
  BgimgAlignment get alignment;
  BgimgThemeMode? get selectedMode;
  double get blur;
  double get opacity;

  /// Create a copy of BgimgModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BgimgModelCopyWith<BgimgModel> get copyWith =>
      _$BgimgModelCopyWithImpl<BgimgModel>(this as BgimgModel, _$identity);

  /// Serializes this BgimgModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BgimgModel &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.nightPath, nightPath) ||
                other.nightPath == nightPath) &&
            (identical(other.alignment, alignment) ||
                other.alignment == alignment) &&
            (identical(other.selectedMode, selectedMode) ||
                other.selectedMode == selectedMode) &&
            (identical(other.blur, blur) || other.blur == blur) &&
            (identical(other.opacity, opacity) || other.opacity == opacity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, type, path, nightPath, alignment,
      selectedMode, blur, opacity);

  @override
  String toString() {
    return 'BgimgModel(type: $type, path: $path, nightPath: $nightPath, alignment: $alignment, selectedMode: $selectedMode, blur: $blur, opacity: $opacity)';
  }
}

/// @nodoc
abstract mixin class $BgimgModelCopyWith<$Res> {
  factory $BgimgModelCopyWith(
          BgimgModel value, $Res Function(BgimgModel) _then) =
      _$BgimgModelCopyWithImpl;
  @useResult
  $Res call(
      {BgimgType type,
      String path,
      String? nightPath,
      BgimgAlignment alignment,
      BgimgThemeMode? selectedMode,
      double blur,
      double opacity});
}

/// @nodoc
class _$BgimgModelCopyWithImpl<$Res> implements $BgimgModelCopyWith<$Res> {
  _$BgimgModelCopyWithImpl(this._self, this._then);

  final BgimgModel _self;
  final $Res Function(BgimgModel) _then;

  /// Create a copy of BgimgModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? path = null,
    Object? nightPath = freezed,
    Object? alignment = null,
    Object? selectedMode = freezed,
    Object? blur = null,
    Object? opacity = null,
  }) {
    return _then(_self.copyWith(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as BgimgType,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      nightPath: freezed == nightPath
          ? _self.nightPath
          : nightPath // ignore: cast_nullable_to_non_nullable
              as String?,
      alignment: null == alignment
          ? _self.alignment
          : alignment // ignore: cast_nullable_to_non_nullable
              as BgimgAlignment,
      selectedMode: freezed == selectedMode
          ? _self.selectedMode
          : selectedMode // ignore: cast_nullable_to_non_nullable
              as BgimgThemeMode?,
      blur: null == blur
          ? _self.blur
          : blur // ignore: cast_nullable_to_non_nullable
              as double,
      opacity: null == opacity
          ? _self.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BgimgModel extends BgimgModel {
  const _BgimgModel(
      {required this.type,
      required this.path,
      this.nightPath,
      required this.alignment,
      this.selectedMode,
      this.blur = 0.0,
      this.opacity = 1.0})
      : super._();
  factory _BgimgModel.fromJson(Map<String, dynamic> json) =>
      _$BgimgModelFromJson(json);

  @override
  final BgimgType type;
  @override
  final String path;
  @override
  final String? nightPath;
  @override
  final BgimgAlignment alignment;
  @override
  final BgimgThemeMode? selectedMode;
  @override
  @JsonKey()
  final double blur;
  @override
  @JsonKey()
  final double opacity;

  /// Create a copy of BgimgModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BgimgModelCopyWith<_BgimgModel> get copyWith =>
      __$BgimgModelCopyWithImpl<_BgimgModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BgimgModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BgimgModel &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.nightPath, nightPath) ||
                other.nightPath == nightPath) &&
            (identical(other.alignment, alignment) ||
                other.alignment == alignment) &&
            (identical(other.selectedMode, selectedMode) ||
                other.selectedMode == selectedMode) &&
            (identical(other.blur, blur) || other.blur == blur) &&
            (identical(other.opacity, opacity) || other.opacity == opacity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, type, path, nightPath, alignment,
      selectedMode, blur, opacity);

  @override
  String toString() {
    return 'BgimgModel(type: $type, path: $path, nightPath: $nightPath, alignment: $alignment, selectedMode: $selectedMode, blur: $blur, opacity: $opacity)';
  }
}

/// @nodoc
abstract mixin class _$BgimgModelCopyWith<$Res>
    implements $BgimgModelCopyWith<$Res> {
  factory _$BgimgModelCopyWith(
          _BgimgModel value, $Res Function(_BgimgModel) _then) =
      __$BgimgModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {BgimgType type,
      String path,
      String? nightPath,
      BgimgAlignment alignment,
      BgimgThemeMode? selectedMode,
      double blur,
      double opacity});
}

/// @nodoc
class __$BgimgModelCopyWithImpl<$Res> implements _$BgimgModelCopyWith<$Res> {
  __$BgimgModelCopyWithImpl(this._self, this._then);

  final _BgimgModel _self;
  final $Res Function(_BgimgModel) _then;

  /// Create a copy of BgimgModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? type = null,
    Object? path = null,
    Object? nightPath = freezed,
    Object? alignment = null,
    Object? selectedMode = freezed,
    Object? blur = null,
    Object? opacity = null,
  }) {
    return _then(_BgimgModel(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as BgimgType,
      path: null == path
          ? _self.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      nightPath: freezed == nightPath
          ? _self.nightPath
          : nightPath // ignore: cast_nullable_to_non_nullable
              as String?,
      alignment: null == alignment
          ? _self.alignment
          : alignment // ignore: cast_nullable_to_non_nullable
              as BgimgAlignment,
      selectedMode: freezed == selectedMode
          ? _self.selectedMode
          : selectedMode // ignore: cast_nullable_to_non_nullable
              as BgimgThemeMode?,
      blur: null == blur
          ? _self.blur
          : blur // ignore: cast_nullable_to_non_nullable
              as double,
      opacity: null == opacity
          ? _self.opacity
          : opacity // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

// dart format on
