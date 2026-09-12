// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tb_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TbGroup {
  int get id;
  String get name;
  int? get parentId;
  int get isDeleted;
  String? get createTime;
  String? get updateTime;

  /// Create a copy of TbGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TbGroupCopyWith<TbGroup> get copyWith =>
      _$TbGroupCopyWithImpl<TbGroup>(this as TbGroup, _$identity);

  /// Serializes this TbGroup to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TbGroup &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.createTime, createTime) ||
                other.createTime == createTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, parentId, isDeleted, createTime, updateTime);

  @override
  String toString() {
    return 'TbGroup(id: $id, name: $name, parentId: $parentId, isDeleted: $isDeleted, createTime: $createTime, updateTime: $updateTime)';
  }
}

/// @nodoc
abstract mixin class $TbGroupCopyWith<$Res> {
  factory $TbGroupCopyWith(TbGroup value, $Res Function(TbGroup) _then) =
      _$TbGroupCopyWithImpl;
  @useResult
  $Res call(
      {int id,
      String name,
      int? parentId,
      int isDeleted,
      String? createTime,
      String? updateTime});
}

/// @nodoc
class _$TbGroupCopyWithImpl<$Res> implements $TbGroupCopyWith<$Res> {
  _$TbGroupCopyWithImpl(this._self, this._then);

  final TbGroup _self;
  final $Res Function(TbGroup) _then;

  /// Create a copy of TbGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentId = freezed,
    Object? isDeleted = null,
    Object? createTime = freezed,
    Object? updateTime = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as int?,
      isDeleted: null == isDeleted
          ? _self.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as int,
      createTime: freezed == createTime
          ? _self.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as String?,
      updateTime: freezed == updateTime
          ? _self.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _TbGroup implements TbGroup {
  const _TbGroup(
      {required this.id,
      required this.name,
      this.parentId,
      this.isDeleted = 0,
      this.createTime,
      this.updateTime});
  factory _TbGroup.fromJson(Map<String, dynamic> json) =>
      _$TbGroupFromJson(json);

  @override
  final int id;
  @override
  final String name;
  @override
  final int? parentId;
  @override
  @JsonKey()
  final int isDeleted;
  @override
  final String? createTime;
  @override
  final String? updateTime;

  /// Create a copy of TbGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TbGroupCopyWith<_TbGroup> get copyWith =>
      __$TbGroupCopyWithImpl<_TbGroup>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TbGroupToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TbGroup &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.createTime, createTime) ||
                other.createTime == createTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, parentId, isDeleted, createTime, updateTime);

  @override
  String toString() {
    return 'TbGroup(id: $id, name: $name, parentId: $parentId, isDeleted: $isDeleted, createTime: $createTime, updateTime: $updateTime)';
  }
}

/// @nodoc
abstract mixin class _$TbGroupCopyWith<$Res> implements $TbGroupCopyWith<$Res> {
  factory _$TbGroupCopyWith(_TbGroup value, $Res Function(_TbGroup) _then) =
      __$TbGroupCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int id,
      String name,
      int? parentId,
      int isDeleted,
      String? createTime,
      String? updateTime});
}

/// @nodoc
class __$TbGroupCopyWithImpl<$Res> implements _$TbGroupCopyWith<$Res> {
  __$TbGroupCopyWithImpl(this._self, this._then);

  final _TbGroup _self;
  final $Res Function(_TbGroup) _then;

  /// Create a copy of TbGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? parentId = freezed,
    Object? isDeleted = null,
    Object? createTime = freezed,
    Object? updateTime = freezed,
  }) {
    return _then(_TbGroup(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as int?,
      isDeleted: null == isDeleted
          ? _self.isDeleted
          : isDeleted // ignore: cast_nullable_to_non_nullable
              as int,
      createTime: freezed == createTime
          ? _self.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as String?,
      updateTime: freezed == updateTime
          ? _self.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
