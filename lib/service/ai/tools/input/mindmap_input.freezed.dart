// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mindmap_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MindmapInput {
  String get title;
  String get hierarchicalList;

  /// Create a copy of MindmapInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MindmapInputCopyWith<MindmapInput> get copyWith =>
      _$MindmapInputCopyWithImpl<MindmapInput>(
          this as MindmapInput, _$identity);

  /// Serializes this MindmapInput to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MindmapInput &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.hierarchicalList, hierarchicalList) ||
                other.hierarchicalList == hierarchicalList));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, title, hierarchicalList);

  @override
  String toString() {
    return 'MindmapInput(title: $title, hierarchicalList: $hierarchicalList)';
  }
}

/// @nodoc
abstract mixin class $MindmapInputCopyWith<$Res> {
  factory $MindmapInputCopyWith(
          MindmapInput value, $Res Function(MindmapInput) _then) =
      _$MindmapInputCopyWithImpl;
  @useResult
  $Res call({String title, String hierarchicalList});
}

/// @nodoc
class _$MindmapInputCopyWithImpl<$Res> implements $MindmapInputCopyWith<$Res> {
  _$MindmapInputCopyWithImpl(this._self, this._then);

  final MindmapInput _self;
  final $Res Function(MindmapInput) _then;

  /// Create a copy of MindmapInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? hierarchicalList = null,
  }) {
    return _then(_self.copyWith(
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      hierarchicalList: null == hierarchicalList
          ? _self.hierarchicalList
          : hierarchicalList // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _MindmapInput extends MindmapInput {
  const _MindmapInput({required this.title, required this.hierarchicalList})
      : super._();
  factory _MindmapInput.fromJson(Map<String, dynamic> json) =>
      _$MindmapInputFromJson(json);

  @override
  final String title;
  @override
  final String hierarchicalList;

  /// Create a copy of MindmapInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MindmapInputCopyWith<_MindmapInput> get copyWith =>
      __$MindmapInputCopyWithImpl<_MindmapInput>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MindmapInputToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MindmapInput &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.hierarchicalList, hierarchicalList) ||
                other.hierarchicalList == hierarchicalList));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, title, hierarchicalList);

  @override
  String toString() {
    return 'MindmapInput(title: $title, hierarchicalList: $hierarchicalList)';
  }
}

/// @nodoc
abstract mixin class _$MindmapInputCopyWith<$Res>
    implements $MindmapInputCopyWith<$Res> {
  factory _$MindmapInputCopyWith(
          _MindmapInput value, $Res Function(_MindmapInput) _then) =
      __$MindmapInputCopyWithImpl;
  @override
  @useResult
  $Res call({String title, String hierarchicalList});
}

/// @nodoc
class __$MindmapInputCopyWithImpl<$Res>
    implements _$MindmapInputCopyWith<$Res> {
  __$MindmapInputCopyWithImpl(this._self, this._then);

  final _MindmapInput _self;
  final $Res Function(_MindmapInput) _then;

  /// Create a copy of MindmapInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? title = null,
    Object? hierarchicalList = null,
  }) {
    return _then(_MindmapInput(
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      hierarchicalList: null == hierarchicalList
          ? _self.hierarchicalList
          : hierarchicalList // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
