// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncStatusModel {
  List<int> get localOnly;
  List<int> get remoteOnly;
  List<int> get both;
  List<int> get nonExistent;
  List<int> get downloading;
  List<int> get uploading;

  /// Create a copy of SyncStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SyncStatusModelCopyWith<SyncStatusModel> get copyWith =>
      _$SyncStatusModelCopyWithImpl<SyncStatusModel>(
          this as SyncStatusModel, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SyncStatusModel &&
            const DeepCollectionEquality().equals(other.localOnly, localOnly) &&
            const DeepCollectionEquality()
                .equals(other.remoteOnly, remoteOnly) &&
            const DeepCollectionEquality().equals(other.both, both) &&
            const DeepCollectionEquality()
                .equals(other.nonExistent, nonExistent) &&
            const DeepCollectionEquality()
                .equals(other.downloading, downloading) &&
            const DeepCollectionEquality().equals(other.uploading, uploading));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(localOnly),
      const DeepCollectionEquality().hash(remoteOnly),
      const DeepCollectionEquality().hash(both),
      const DeepCollectionEquality().hash(nonExistent),
      const DeepCollectionEquality().hash(downloading),
      const DeepCollectionEquality().hash(uploading));

  @override
  String toString() {
    return 'SyncStatusModel(localOnly: $localOnly, remoteOnly: $remoteOnly, both: $both, nonExistent: $nonExistent, downloading: $downloading, uploading: $uploading)';
  }
}

/// @nodoc
abstract mixin class $SyncStatusModelCopyWith<$Res> {
  factory $SyncStatusModelCopyWith(
          SyncStatusModel value, $Res Function(SyncStatusModel) _then) =
      _$SyncStatusModelCopyWithImpl;
  @useResult
  $Res call(
      {List<int> localOnly,
      List<int> remoteOnly,
      List<int> both,
      List<int> nonExistent,
      List<int> downloading,
      List<int> uploading});
}

/// @nodoc
class _$SyncStatusModelCopyWithImpl<$Res>
    implements $SyncStatusModelCopyWith<$Res> {
  _$SyncStatusModelCopyWithImpl(this._self, this._then);

  final SyncStatusModel _self;
  final $Res Function(SyncStatusModel) _then;

  /// Create a copy of SyncStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? localOnly = null,
    Object? remoteOnly = null,
    Object? both = null,
    Object? nonExistent = null,
    Object? downloading = null,
    Object? uploading = null,
  }) {
    return _then(_self.copyWith(
      localOnly: null == localOnly
          ? _self.localOnly
          : localOnly // ignore: cast_nullable_to_non_nullable
              as List<int>,
      remoteOnly: null == remoteOnly
          ? _self.remoteOnly
          : remoteOnly // ignore: cast_nullable_to_non_nullable
              as List<int>,
      both: null == both
          ? _self.both
          : both // ignore: cast_nullable_to_non_nullable
              as List<int>,
      nonExistent: null == nonExistent
          ? _self.nonExistent
          : nonExistent // ignore: cast_nullable_to_non_nullable
              as List<int>,
      downloading: null == downloading
          ? _self.downloading
          : downloading // ignore: cast_nullable_to_non_nullable
              as List<int>,
      uploading: null == uploading
          ? _self.uploading
          : uploading // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

/// @nodoc

class _SyncStatusModel implements SyncStatusModel {
  const _SyncStatusModel(
      {required final List<int> localOnly,
      required final List<int> remoteOnly,
      required final List<int> both,
      required final List<int> nonExistent,
      required final List<int> downloading,
      required final List<int> uploading})
      : _localOnly = localOnly,
        _remoteOnly = remoteOnly,
        _both = both,
        _nonExistent = nonExistent,
        _downloading = downloading,
        _uploading = uploading;

  final List<int> _localOnly;
  @override
  List<int> get localOnly {
    if (_localOnly is EqualUnmodifiableListView) return _localOnly;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_localOnly);
  }

  final List<int> _remoteOnly;
  @override
  List<int> get remoteOnly {
    if (_remoteOnly is EqualUnmodifiableListView) return _remoteOnly;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_remoteOnly);
  }

  final List<int> _both;
  @override
  List<int> get both {
    if (_both is EqualUnmodifiableListView) return _both;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_both);
  }

  final List<int> _nonExistent;
  @override
  List<int> get nonExistent {
    if (_nonExistent is EqualUnmodifiableListView) return _nonExistent;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nonExistent);
  }

  final List<int> _downloading;
  @override
  List<int> get downloading {
    if (_downloading is EqualUnmodifiableListView) return _downloading;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_downloading);
  }

  final List<int> _uploading;
  @override
  List<int> get uploading {
    if (_uploading is EqualUnmodifiableListView) return _uploading;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_uploading);
  }

  /// Create a copy of SyncStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SyncStatusModelCopyWith<_SyncStatusModel> get copyWith =>
      __$SyncStatusModelCopyWithImpl<_SyncStatusModel>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SyncStatusModel &&
            const DeepCollectionEquality()
                .equals(other._localOnly, _localOnly) &&
            const DeepCollectionEquality()
                .equals(other._remoteOnly, _remoteOnly) &&
            const DeepCollectionEquality().equals(other._both, _both) &&
            const DeepCollectionEquality()
                .equals(other._nonExistent, _nonExistent) &&
            const DeepCollectionEquality()
                .equals(other._downloading, _downloading) &&
            const DeepCollectionEquality()
                .equals(other._uploading, _uploading));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_localOnly),
      const DeepCollectionEquality().hash(_remoteOnly),
      const DeepCollectionEquality().hash(_both),
      const DeepCollectionEquality().hash(_nonExistent),
      const DeepCollectionEquality().hash(_downloading),
      const DeepCollectionEquality().hash(_uploading));

  @override
  String toString() {
    return 'SyncStatusModel(localOnly: $localOnly, remoteOnly: $remoteOnly, both: $both, nonExistent: $nonExistent, downloading: $downloading, uploading: $uploading)';
  }
}

/// @nodoc
abstract mixin class _$SyncStatusModelCopyWith<$Res>
    implements $SyncStatusModelCopyWith<$Res> {
  factory _$SyncStatusModelCopyWith(
          _SyncStatusModel value, $Res Function(_SyncStatusModel) _then) =
      __$SyncStatusModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<int> localOnly,
      List<int> remoteOnly,
      List<int> both,
      List<int> nonExistent,
      List<int> downloading,
      List<int> uploading});
}

/// @nodoc
class __$SyncStatusModelCopyWithImpl<$Res>
    implements _$SyncStatusModelCopyWith<$Res> {
  __$SyncStatusModelCopyWithImpl(this._self, this._then);

  final _SyncStatusModel _self;
  final $Res Function(_SyncStatusModel) _then;

  /// Create a copy of SyncStatusModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? localOnly = null,
    Object? remoteOnly = null,
    Object? both = null,
    Object? nonExistent = null,
    Object? downloading = null,
    Object? uploading = null,
  }) {
    return _then(_SyncStatusModel(
      localOnly: null == localOnly
          ? _self._localOnly
          : localOnly // ignore: cast_nullable_to_non_nullable
              as List<int>,
      remoteOnly: null == remoteOnly
          ? _self._remoteOnly
          : remoteOnly // ignore: cast_nullable_to_non_nullable
              as List<int>,
      both: null == both
          ? _self._both
          : both // ignore: cast_nullable_to_non_nullable
              as List<int>,
      nonExistent: null == nonExistent
          ? _self._nonExistent
          : nonExistent // ignore: cast_nullable_to_non_nullable
              as List<int>,
      downloading: null == downloading
          ? _self._downloading
          : downloading // ignore: cast_nullable_to_non_nullable
              as List<int>,
      uploading: null == uploading
          ? _self._uploading
          : uploading // ignore: cast_nullable_to_non_nullable
              as List<int>,
    ));
  }
}

// dart format on
