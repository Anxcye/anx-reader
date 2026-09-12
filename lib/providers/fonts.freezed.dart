// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fonts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LicenseModel implements DiagnosticableTreeMixin {
  String get name;
  String get url;

  /// Create a copy of LicenseModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LicenseModelCopyWith<LicenseModel> get copyWith =>
      _$LicenseModelCopyWithImpl<LicenseModel>(
          this as LicenseModel, _$identity);

  /// Serializes this LicenseModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'LicenseModel'))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('url', url));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LicenseModel &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, url);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'LicenseModel(name: $name, url: $url)';
  }
}

/// @nodoc
abstract mixin class $LicenseModelCopyWith<$Res> {
  factory $LicenseModelCopyWith(
          LicenseModel value, $Res Function(LicenseModel) _then) =
      _$LicenseModelCopyWithImpl;
  @useResult
  $Res call({String name, String url});
}

/// @nodoc
class _$LicenseModelCopyWithImpl<$Res> implements $LicenseModelCopyWith<$Res> {
  _$LicenseModelCopyWithImpl(this._self, this._then);

  final LicenseModel _self;
  final $Res Function(LicenseModel) _then;

  /// Create a copy of LicenseModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? url = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _LicenseModel with DiagnosticableTreeMixin implements LicenseModel {
  const _LicenseModel({required this.name, required this.url});
  factory _LicenseModel.fromJson(Map<String, dynamic> json) =>
      _$LicenseModelFromJson(json);

  @override
  final String name;
  @override
  final String url;

  /// Create a copy of LicenseModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LicenseModelCopyWith<_LicenseModel> get copyWith =>
      __$LicenseModelCopyWithImpl<_LicenseModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$LicenseModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'LicenseModel'))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('url', url));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LicenseModel &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, url);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'LicenseModel(name: $name, url: $url)';
  }
}

/// @nodoc
abstract mixin class _$LicenseModelCopyWith<$Res>
    implements $LicenseModelCopyWith<$Res> {
  factory _$LicenseModelCopyWith(
          _LicenseModel value, $Res Function(_LicenseModel) _then) =
      __$LicenseModelCopyWithImpl;
  @override
  @useResult
  $Res call({String name, String url});
}

/// @nodoc
class __$LicenseModelCopyWithImpl<$Res>
    implements _$LicenseModelCopyWith<$Res> {
  __$LicenseModelCopyWithImpl(this._self, this._then);

  final _LicenseModel _self;
  final $Res Function(_LicenseModel) _then;

  /// Create a copy of LicenseModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? url = null,
  }) {
    return _then(_LicenseModel(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _self.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$RemoteFontModel implements DiagnosticableTreeMixin {
  String get id;
  String get name;
  List<String> get files;
  int get size;
  String get preview;
  String get desc;
  String get official;
  LicenseModel get license;

  /// Create a copy of RemoteFontModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RemoteFontModelCopyWith<RemoteFontModel> get copyWith =>
      _$RemoteFontModelCopyWithImpl<RemoteFontModel>(
          this as RemoteFontModel, _$identity);

  /// Serializes this RemoteFontModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'RemoteFontModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('files', files))
      ..add(DiagnosticsProperty('size', size))
      ..add(DiagnosticsProperty('preview', preview))
      ..add(DiagnosticsProperty('desc', desc))
      ..add(DiagnosticsProperty('official', official))
      ..add(DiagnosticsProperty('license', license));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RemoteFontModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other.files, files) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.preview, preview) || other.preview == preview) &&
            (identical(other.desc, desc) || other.desc == desc) &&
            (identical(other.official, official) ||
                other.official == official) &&
            (identical(other.license, license) || other.license == license));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      const DeepCollectionEquality().hash(files),
      size,
      preview,
      desc,
      official,
      license);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'RemoteFontModel(id: $id, name: $name, files: $files, size: $size, preview: $preview, desc: $desc, official: $official, license: $license)';
  }
}

/// @nodoc
abstract mixin class $RemoteFontModelCopyWith<$Res> {
  factory $RemoteFontModelCopyWith(
          RemoteFontModel value, $Res Function(RemoteFontModel) _then) =
      _$RemoteFontModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      List<String> files,
      int size,
      String preview,
      String desc,
      String official,
      LicenseModel license});

  $LicenseModelCopyWith<$Res> get license;
}

/// @nodoc
class _$RemoteFontModelCopyWithImpl<$Res>
    implements $RemoteFontModelCopyWith<$Res> {
  _$RemoteFontModelCopyWithImpl(this._self, this._then);

  final RemoteFontModel _self;
  final $Res Function(RemoteFontModel) _then;

  /// Create a copy of RemoteFontModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? files = null,
    Object? size = null,
    Object? preview = null,
    Object? desc = null,
    Object? official = null,
    Object? license = null,
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
      files: null == files
          ? _self.files
          : files // ignore: cast_nullable_to_non_nullable
              as List<String>,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      preview: null == preview
          ? _self.preview
          : preview // ignore: cast_nullable_to_non_nullable
              as String,
      desc: null == desc
          ? _self.desc
          : desc // ignore: cast_nullable_to_non_nullable
              as String,
      official: null == official
          ? _self.official
          : official // ignore: cast_nullable_to_non_nullable
              as String,
      license: null == license
          ? _self.license
          : license // ignore: cast_nullable_to_non_nullable
              as LicenseModel,
    ));
  }

  /// Create a copy of RemoteFontModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LicenseModelCopyWith<$Res> get license {
    return $LicenseModelCopyWith<$Res>(_self.license, (value) {
      return _then(_self.copyWith(license: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _RemoteFontModel with DiagnosticableTreeMixin implements RemoteFontModel {
  const _RemoteFontModel(
      {required this.id,
      required this.name,
      required final List<String> files,
      required this.size,
      required this.preview,
      required this.desc,
      required this.official,
      required this.license})
      : _files = files;
  factory _RemoteFontModel.fromJson(Map<String, dynamic> json) =>
      _$RemoteFontModelFromJson(json);

  @override
  final String id;
  @override
  final String name;
  final List<String> _files;
  @override
  List<String> get files {
    if (_files is EqualUnmodifiableListView) return _files;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_files);
  }

  @override
  final int size;
  @override
  final String preview;
  @override
  final String desc;
  @override
  final String official;
  @override
  final LicenseModel license;

  /// Create a copy of RemoteFontModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RemoteFontModelCopyWith<_RemoteFontModel> get copyWith =>
      __$RemoteFontModelCopyWithImpl<_RemoteFontModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RemoteFontModelToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'RemoteFontModel'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('name', name))
      ..add(DiagnosticsProperty('files', files))
      ..add(DiagnosticsProperty('size', size))
      ..add(DiagnosticsProperty('preview', preview))
      ..add(DiagnosticsProperty('desc', desc))
      ..add(DiagnosticsProperty('official', official))
      ..add(DiagnosticsProperty('license', license));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RemoteFontModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._files, _files) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.preview, preview) || other.preview == preview) &&
            (identical(other.desc, desc) || other.desc == desc) &&
            (identical(other.official, official) ||
                other.official == official) &&
            (identical(other.license, license) || other.license == license));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      const DeepCollectionEquality().hash(_files),
      size,
      preview,
      desc,
      official,
      license);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'RemoteFontModel(id: $id, name: $name, files: $files, size: $size, preview: $preview, desc: $desc, official: $official, license: $license)';
  }
}

/// @nodoc
abstract mixin class _$RemoteFontModelCopyWith<$Res>
    implements $RemoteFontModelCopyWith<$Res> {
  factory _$RemoteFontModelCopyWith(
          _RemoteFontModel value, $Res Function(_RemoteFontModel) _then) =
      __$RemoteFontModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      List<String> files,
      int size,
      String preview,
      String desc,
      String official,
      LicenseModel license});

  @override
  $LicenseModelCopyWith<$Res> get license;
}

/// @nodoc
class __$RemoteFontModelCopyWithImpl<$Res>
    implements _$RemoteFontModelCopyWith<$Res> {
  __$RemoteFontModelCopyWithImpl(this._self, this._then);

  final _RemoteFontModel _self;
  final $Res Function(_RemoteFontModel) _then;

  /// Create a copy of RemoteFontModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? files = null,
    Object? size = null,
    Object? preview = null,
    Object? desc = null,
    Object? official = null,
    Object? license = null,
  }) {
    return _then(_RemoteFontModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      files: null == files
          ? _self._files
          : files // ignore: cast_nullable_to_non_nullable
              as List<String>,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as int,
      preview: null == preview
          ? _self.preview
          : preview // ignore: cast_nullable_to_non_nullable
              as String,
      desc: null == desc
          ? _self.desc
          : desc // ignore: cast_nullable_to_non_nullable
              as String,
      official: null == official
          ? _self.official
          : official // ignore: cast_nullable_to_non_nullable
              as String,
      license: null == license
          ? _self.license
          : license // ignore: cast_nullable_to_non_nullable
              as LicenseModel,
    ));
  }

  /// Create a copy of RemoteFontModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $LicenseModelCopyWith<$Res> get license {
    return $LicenseModelCopyWith<$Res>(_self.license, (value) {
      return _then(_self.copyWith(license: value));
    });
  }
}

/// @nodoc
mixin _$FontDownloadState implements DiagnosticableTreeMixin {
  String get fontId;
  String get filePath;
  DownloadStatus get status;
  double get progress;
  String? get error;
  CancelToken? get cancelToken;

  /// Create a copy of FontDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FontDownloadStateCopyWith<FontDownloadState> get copyWith =>
      _$FontDownloadStateCopyWithImpl<FontDownloadState>(
          this as FontDownloadState, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'FontDownloadState'))
      ..add(DiagnosticsProperty('fontId', fontId))
      ..add(DiagnosticsProperty('filePath', filePath))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('progress', progress))
      ..add(DiagnosticsProperty('error', error))
      ..add(DiagnosticsProperty('cancelToken', cancelToken));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FontDownloadState &&
            (identical(other.fontId, fontId) || other.fontId == fontId) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.cancelToken, cancelToken) ||
                other.cancelToken == cancelToken));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, fontId, filePath, status, progress, error, cancelToken);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FontDownloadState(fontId: $fontId, filePath: $filePath, status: $status, progress: $progress, error: $error, cancelToken: $cancelToken)';
  }
}

/// @nodoc
abstract mixin class $FontDownloadStateCopyWith<$Res> {
  factory $FontDownloadStateCopyWith(
          FontDownloadState value, $Res Function(FontDownloadState) _then) =
      _$FontDownloadStateCopyWithImpl;
  @useResult
  $Res call(
      {String fontId,
      String filePath,
      DownloadStatus status,
      double progress,
      String? error,
      CancelToken? cancelToken});
}

/// @nodoc
class _$FontDownloadStateCopyWithImpl<$Res>
    implements $FontDownloadStateCopyWith<$Res> {
  _$FontDownloadStateCopyWithImpl(this._self, this._then);

  final FontDownloadState _self;
  final $Res Function(FontDownloadState) _then;

  /// Create a copy of FontDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fontId = null,
    Object? filePath = null,
    Object? status = null,
    Object? progress = null,
    Object? error = freezed,
    Object? cancelToken = freezed,
  }) {
    return _then(_self.copyWith(
      fontId: null == fontId
          ? _self.fontId
          : fontId // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _self.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as DownloadStatus,
      progress: null == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      cancelToken: freezed == cancelToken
          ? _self.cancelToken
          : cancelToken // ignore: cast_nullable_to_non_nullable
              as CancelToken?,
    ));
  }
}

/// @nodoc

class _FontDownloadState
    with DiagnosticableTreeMixin
    implements FontDownloadState {
  const _FontDownloadState(
      {required this.fontId,
      required this.filePath,
      required this.status,
      this.progress = 0.0,
      this.error,
      this.cancelToken});

  @override
  final String fontId;
  @override
  final String filePath;
  @override
  final DownloadStatus status;
  @override
  @JsonKey()
  final double progress;
  @override
  final String? error;
  @override
  final CancelToken? cancelToken;

  /// Create a copy of FontDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FontDownloadStateCopyWith<_FontDownloadState> get copyWith =>
      __$FontDownloadStateCopyWithImpl<_FontDownloadState>(this, _$identity);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'FontDownloadState'))
      ..add(DiagnosticsProperty('fontId', fontId))
      ..add(DiagnosticsProperty('filePath', filePath))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('progress', progress))
      ..add(DiagnosticsProperty('error', error))
      ..add(DiagnosticsProperty('cancelToken', cancelToken));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FontDownloadState &&
            (identical(other.fontId, fontId) || other.fontId == fontId) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.cancelToken, cancelToken) ||
                other.cancelToken == cancelToken));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, fontId, filePath, status, progress, error, cancelToken);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FontDownloadState(fontId: $fontId, filePath: $filePath, status: $status, progress: $progress, error: $error, cancelToken: $cancelToken)';
  }
}

/// @nodoc
abstract mixin class _$FontDownloadStateCopyWith<$Res>
    implements $FontDownloadStateCopyWith<$Res> {
  factory _$FontDownloadStateCopyWith(
          _FontDownloadState value, $Res Function(_FontDownloadState) _then) =
      __$FontDownloadStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String fontId,
      String filePath,
      DownloadStatus status,
      double progress,
      String? error,
      CancelToken? cancelToken});
}

/// @nodoc
class __$FontDownloadStateCopyWithImpl<$Res>
    implements _$FontDownloadStateCopyWith<$Res> {
  __$FontDownloadStateCopyWithImpl(this._self, this._then);

  final _FontDownloadState _self;
  final $Res Function(_FontDownloadState) _then;

  /// Create a copy of FontDownloadState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fontId = null,
    Object? filePath = null,
    Object? status = null,
    Object? progress = null,
    Object? error = freezed,
    Object? cancelToken = freezed,
  }) {
    return _then(_FontDownloadState(
      fontId: null == fontId
          ? _self.fontId
          : fontId // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _self.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as DownloadStatus,
      progress: null == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      error: freezed == error
          ? _self.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      cancelToken: freezed == cancelToken
          ? _self.cancelToken
          : cancelToken // ignore: cast_nullable_to_non_nullable
              as CancelToken?,
    ));
  }
}

// dart format on
