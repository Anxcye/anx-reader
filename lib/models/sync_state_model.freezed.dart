// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_state_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
SyncStateModel _$SyncStateModelFromJson(Map<String, dynamic> json) {
  return _SyncState.fromJson(json);
}

/// @nodoc
mixin _$SyncStateModel {
  SyncDirection get direction;
  bool get isSyncing;
  int get total;
  int get count;
  String get fileName;

  /// Create a copy of SyncStateModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SyncStateModelCopyWith<SyncStateModel> get copyWith =>
      _$SyncStateModelCopyWithImpl<SyncStateModel>(
          this as SyncStateModel, _$identity);

  /// Serializes this SyncStateModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SyncStateModel &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.isSyncing, isSyncing) ||
                other.isSyncing == isSyncing) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, direction, isSyncing, total, count, fileName);

  @override
  String toString() {
    return 'SyncStateModel(direction: $direction, isSyncing: $isSyncing, total: $total, count: $count, fileName: $fileName)';
  }
}

/// @nodoc
abstract mixin class $SyncStateModelCopyWith<$Res> {
  factory $SyncStateModelCopyWith(
          SyncStateModel value, $Res Function(SyncStateModel) _then) =
      _$SyncStateModelCopyWithImpl;
  @useResult
  $Res call(
      {SyncDirection direction,
      bool isSyncing,
      int total,
      int count,
      String fileName});
}

/// @nodoc
class _$SyncStateModelCopyWithImpl<$Res>
    implements $SyncStateModelCopyWith<$Res> {
  _$SyncStateModelCopyWithImpl(this._self, this._then);

  final SyncStateModel _self;
  final $Res Function(SyncStateModel) _then;

  /// Create a copy of SyncStateModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? direction = null,
    Object? isSyncing = null,
    Object? total = null,
    Object? count = null,
    Object? fileName = null,
  }) {
    return _then(_self.copyWith(
      direction: null == direction
          ? _self.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as SyncDirection,
      isSyncing: null == isSyncing
          ? _self.isSyncing
          : isSyncing // ignore: cast_nullable_to_non_nullable
              as bool,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      count: null == count
          ? _self.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _SyncState implements SyncStateModel {
  const _SyncState(
      {required this.direction,
      required this.isSyncing,
      required this.total,
      required this.count,
      required this.fileName});
  factory _SyncState.fromJson(Map<String, dynamic> json) =>
      _$SyncStateFromJson(json);

  @override
  final SyncDirection direction;
  @override
  final bool isSyncing;
  @override
  final int total;
  @override
  final int count;
  @override
  final String fileName;

  /// Create a copy of SyncStateModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SyncStateCopyWith<_SyncState> get copyWith =>
      __$SyncStateCopyWithImpl<_SyncState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SyncStateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SyncState &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.isSyncing, isSyncing) ||
                other.isSyncing == isSyncing) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.count, count) || other.count == count) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, direction, isSyncing, total, count, fileName);

  @override
  String toString() {
    return 'SyncStateModel(direction: $direction, isSyncing: $isSyncing, total: $total, count: $count, fileName: $fileName)';
  }
}

/// @nodoc
abstract mixin class _$SyncStateCopyWith<$Res>
    implements $SyncStateModelCopyWith<$Res> {
  factory _$SyncStateCopyWith(
          _SyncState value, $Res Function(_SyncState) _then) =
      __$SyncStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {SyncDirection direction,
      bool isSyncing,
      int total,
      int count,
      String fileName});
}

/// @nodoc
class __$SyncStateCopyWithImpl<$Res> implements _$SyncStateCopyWith<$Res> {
  __$SyncStateCopyWithImpl(this._self, this._then);

  final _SyncState _self;
  final $Res Function(_SyncState) _then;

  /// Create a copy of SyncStateModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? direction = null,
    Object? isSyncing = null,
    Object? total = null,
    Object? count = null,
    Object? fileName = null,
  }) {
    return _then(_SyncState(
      direction: null == direction
          ? _self.direction
          : direction // ignore: cast_nullable_to_non_nullable
              as SyncDirection,
      isSyncing: null == isSyncing
          ? _self.isSyncing
          : isSyncing // ignore: cast_nullable_to_non_nullable
              as bool,
      total: null == total
          ? _self.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      count: null == count
          ? _self.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      fileName: null == fileName
          ? _self.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
