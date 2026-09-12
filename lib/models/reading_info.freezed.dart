// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReadingInfoSectionModel {
  ReadingInfoEnum get left;
  ReadingInfoEnum get center;
  ReadingInfoEnum get right;
  double get verticalMargin;
  double get leftMargin;
  double get rightMargin;
  double get fontSize;

  /// Create a copy of ReadingInfoSectionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReadingInfoSectionModelCopyWith<ReadingInfoSectionModel> get copyWith =>
      _$ReadingInfoSectionModelCopyWithImpl<ReadingInfoSectionModel>(
          this as ReadingInfoSectionModel, _$identity);

  /// Serializes this ReadingInfoSectionModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReadingInfoSectionModel &&
            (identical(other.left, left) || other.left == left) &&
            (identical(other.center, center) || other.center == center) &&
            (identical(other.right, right) || other.right == right) &&
            (identical(other.verticalMargin, verticalMargin) ||
                other.verticalMargin == verticalMargin) &&
            (identical(other.leftMargin, leftMargin) ||
                other.leftMargin == leftMargin) &&
            (identical(other.rightMargin, rightMargin) ||
                other.rightMargin == rightMargin) &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, left, center, right,
      verticalMargin, leftMargin, rightMargin, fontSize);

  @override
  String toString() {
    return 'ReadingInfoSectionModel(left: $left, center: $center, right: $right, verticalMargin: $verticalMargin, leftMargin: $leftMargin, rightMargin: $rightMargin, fontSize: $fontSize)';
  }
}

/// @nodoc
abstract mixin class $ReadingInfoSectionModelCopyWith<$Res> {
  factory $ReadingInfoSectionModelCopyWith(ReadingInfoSectionModel value,
          $Res Function(ReadingInfoSectionModel) _then) =
      _$ReadingInfoSectionModelCopyWithImpl;
  @useResult
  $Res call(
      {ReadingInfoEnum left,
      ReadingInfoEnum center,
      ReadingInfoEnum right,
      double verticalMargin,
      double leftMargin,
      double rightMargin,
      double fontSize});
}

/// @nodoc
class _$ReadingInfoSectionModelCopyWithImpl<$Res>
    implements $ReadingInfoSectionModelCopyWith<$Res> {
  _$ReadingInfoSectionModelCopyWithImpl(this._self, this._then);

  final ReadingInfoSectionModel _self;
  final $Res Function(ReadingInfoSectionModel) _then;

  /// Create a copy of ReadingInfoSectionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? left = null,
    Object? center = null,
    Object? right = null,
    Object? verticalMargin = null,
    Object? leftMargin = null,
    Object? rightMargin = null,
    Object? fontSize = null,
  }) {
    return _then(_self.copyWith(
      left: null == left
          ? _self.left
          : left // ignore: cast_nullable_to_non_nullable
              as ReadingInfoEnum,
      center: null == center
          ? _self.center
          : center // ignore: cast_nullable_to_non_nullable
              as ReadingInfoEnum,
      right: null == right
          ? _self.right
          : right // ignore: cast_nullable_to_non_nullable
              as ReadingInfoEnum,
      verticalMargin: null == verticalMargin
          ? _self.verticalMargin
          : verticalMargin // ignore: cast_nullable_to_non_nullable
              as double,
      leftMargin: null == leftMargin
          ? _self.leftMargin
          : leftMargin // ignore: cast_nullable_to_non_nullable
              as double,
      rightMargin: null == rightMargin
          ? _self.rightMargin
          : rightMargin // ignore: cast_nullable_to_non_nullable
              as double,
      fontSize: null == fontSize
          ? _self.fontSize
          : fontSize // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ReadingInfoSectionModel implements ReadingInfoSectionModel {
  const _ReadingInfoSectionModel(
      {this.left = ReadingInfoEnum.none,
      this.center = ReadingInfoEnum.none,
      this.right = ReadingInfoEnum.none,
      this.verticalMargin = 0,
      this.leftMargin = 20,
      this.rightMargin = 20,
      this.fontSize = 10});
  factory _ReadingInfoSectionModel.fromJson(Map<String, dynamic> json) =>
      _$ReadingInfoSectionModelFromJson(json);

  @override
  @JsonKey()
  final ReadingInfoEnum left;
  @override
  @JsonKey()
  final ReadingInfoEnum center;
  @override
  @JsonKey()
  final ReadingInfoEnum right;
  @override
  @JsonKey()
  final double verticalMargin;
  @override
  @JsonKey()
  final double leftMargin;
  @override
  @JsonKey()
  final double rightMargin;
  @override
  @JsonKey()
  final double fontSize;

  /// Create a copy of ReadingInfoSectionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ReadingInfoSectionModelCopyWith<_ReadingInfoSectionModel> get copyWith =>
      __$ReadingInfoSectionModelCopyWithImpl<_ReadingInfoSectionModel>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ReadingInfoSectionModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ReadingInfoSectionModel &&
            (identical(other.left, left) || other.left == left) &&
            (identical(other.center, center) || other.center == center) &&
            (identical(other.right, right) || other.right == right) &&
            (identical(other.verticalMargin, verticalMargin) ||
                other.verticalMargin == verticalMargin) &&
            (identical(other.leftMargin, leftMargin) ||
                other.leftMargin == leftMargin) &&
            (identical(other.rightMargin, rightMargin) ||
                other.rightMargin == rightMargin) &&
            (identical(other.fontSize, fontSize) ||
                other.fontSize == fontSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, left, center, right,
      verticalMargin, leftMargin, rightMargin, fontSize);

  @override
  String toString() {
    return 'ReadingInfoSectionModel(left: $left, center: $center, right: $right, verticalMargin: $verticalMargin, leftMargin: $leftMargin, rightMargin: $rightMargin, fontSize: $fontSize)';
  }
}

/// @nodoc
abstract mixin class _$ReadingInfoSectionModelCopyWith<$Res>
    implements $ReadingInfoSectionModelCopyWith<$Res> {
  factory _$ReadingInfoSectionModelCopyWith(_ReadingInfoSectionModel value,
          $Res Function(_ReadingInfoSectionModel) _then) =
      __$ReadingInfoSectionModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {ReadingInfoEnum left,
      ReadingInfoEnum center,
      ReadingInfoEnum right,
      double verticalMargin,
      double leftMargin,
      double rightMargin,
      double fontSize});
}

/// @nodoc
class __$ReadingInfoSectionModelCopyWithImpl<$Res>
    implements _$ReadingInfoSectionModelCopyWith<$Res> {
  __$ReadingInfoSectionModelCopyWithImpl(this._self, this._then);

  final _ReadingInfoSectionModel _self;
  final $Res Function(_ReadingInfoSectionModel) _then;

  /// Create a copy of ReadingInfoSectionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? left = null,
    Object? center = null,
    Object? right = null,
    Object? verticalMargin = null,
    Object? leftMargin = null,
    Object? rightMargin = null,
    Object? fontSize = null,
  }) {
    return _then(_ReadingInfoSectionModel(
      left: null == left
          ? _self.left
          : left // ignore: cast_nullable_to_non_nullable
              as ReadingInfoEnum,
      center: null == center
          ? _self.center
          : center // ignore: cast_nullable_to_non_nullable
              as ReadingInfoEnum,
      right: null == right
          ? _self.right
          : right // ignore: cast_nullable_to_non_nullable
              as ReadingInfoEnum,
      verticalMargin: null == verticalMargin
          ? _self.verticalMargin
          : verticalMargin // ignore: cast_nullable_to_non_nullable
              as double,
      leftMargin: null == leftMargin
          ? _self.leftMargin
          : leftMargin // ignore: cast_nullable_to_non_nullable
              as double,
      rightMargin: null == rightMargin
          ? _self.rightMargin
          : rightMargin // ignore: cast_nullable_to_non_nullable
              as double,
      fontSize: null == fontSize
          ? _self.fontSize
          : fontSize // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
mixin _$ReadingInfoModel {
  ReadingInfoSectionModel get header;
  ReadingInfoSectionModel get footer;

  /// Create a copy of ReadingInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReadingInfoModelCopyWith<ReadingInfoModel> get copyWith =>
      _$ReadingInfoModelCopyWithImpl<ReadingInfoModel>(
          this as ReadingInfoModel, _$identity);

  /// Serializes this ReadingInfoModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReadingInfoModel &&
            (identical(other.header, header) || other.header == header) &&
            (identical(other.footer, footer) || other.footer == footer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, header, footer);

  @override
  String toString() {
    return 'ReadingInfoModel(header: $header, footer: $footer)';
  }
}

/// @nodoc
abstract mixin class $ReadingInfoModelCopyWith<$Res> {
  factory $ReadingInfoModelCopyWith(
          ReadingInfoModel value, $Res Function(ReadingInfoModel) _then) =
      _$ReadingInfoModelCopyWithImpl;
  @useResult
  $Res call({ReadingInfoSectionModel header, ReadingInfoSectionModel footer});

  $ReadingInfoSectionModelCopyWith<$Res> get header;
  $ReadingInfoSectionModelCopyWith<$Res> get footer;
}

/// @nodoc
class _$ReadingInfoModelCopyWithImpl<$Res>
    implements $ReadingInfoModelCopyWith<$Res> {
  _$ReadingInfoModelCopyWithImpl(this._self, this._then);

  final ReadingInfoModel _self;
  final $Res Function(ReadingInfoModel) _then;

  /// Create a copy of ReadingInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? header = null,
    Object? footer = null,
  }) {
    return _then(_self.copyWith(
      header: null == header
          ? _self.header
          : header // ignore: cast_nullable_to_non_nullable
              as ReadingInfoSectionModel,
      footer: null == footer
          ? _self.footer
          : footer // ignore: cast_nullable_to_non_nullable
              as ReadingInfoSectionModel,
    ));
  }

  /// Create a copy of ReadingInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReadingInfoSectionModelCopyWith<$Res> get header {
    return $ReadingInfoSectionModelCopyWith<$Res>(_self.header, (value) {
      return _then(_self.copyWith(header: value));
    });
  }

  /// Create a copy of ReadingInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReadingInfoSectionModelCopyWith<$Res> get footer {
    return $ReadingInfoSectionModelCopyWith<$Res>(_self.footer, (value) {
      return _then(_self.copyWith(footer: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _ReadingInfoModel implements ReadingInfoModel {
  const _ReadingInfoModel(
      {this.header =
          const ReadingInfoSectionModel(left: ReadingInfoEnum.chapterTitle),
      this.footer = const ReadingInfoSectionModel(
          left: ReadingInfoEnum.batteryAndTime,
          center: ReadingInfoEnum.chapterProgress,
          right: ReadingInfoEnum.bookProgress)});
  factory _ReadingInfoModel.fromJson(Map<String, dynamic> json) =>
      _$ReadingInfoModelFromJson(json);

  @override
  @JsonKey()
  final ReadingInfoSectionModel header;
  @override
  @JsonKey()
  final ReadingInfoSectionModel footer;

  /// Create a copy of ReadingInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ReadingInfoModelCopyWith<_ReadingInfoModel> get copyWith =>
      __$ReadingInfoModelCopyWithImpl<_ReadingInfoModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ReadingInfoModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ReadingInfoModel &&
            (identical(other.header, header) || other.header == header) &&
            (identical(other.footer, footer) || other.footer == footer));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, header, footer);

  @override
  String toString() {
    return 'ReadingInfoModel(header: $header, footer: $footer)';
  }
}

/// @nodoc
abstract mixin class _$ReadingInfoModelCopyWith<$Res>
    implements $ReadingInfoModelCopyWith<$Res> {
  factory _$ReadingInfoModelCopyWith(
          _ReadingInfoModel value, $Res Function(_ReadingInfoModel) _then) =
      __$ReadingInfoModelCopyWithImpl;
  @override
  @useResult
  $Res call({ReadingInfoSectionModel header, ReadingInfoSectionModel footer});

  @override
  $ReadingInfoSectionModelCopyWith<$Res> get header;
  @override
  $ReadingInfoSectionModelCopyWith<$Res> get footer;
}

/// @nodoc
class __$ReadingInfoModelCopyWithImpl<$Res>
    implements _$ReadingInfoModelCopyWith<$Res> {
  __$ReadingInfoModelCopyWithImpl(this._self, this._then);

  final _ReadingInfoModel _self;
  final $Res Function(_ReadingInfoModel) _then;

  /// Create a copy of ReadingInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? header = null,
    Object? footer = null,
  }) {
    return _then(_ReadingInfoModel(
      header: null == header
          ? _self.header
          : header // ignore: cast_nullable_to_non_nullable
              as ReadingInfoSectionModel,
      footer: null == footer
          ? _self.footer
          : footer // ignore: cast_nullable_to_non_nullable
              as ReadingInfoSectionModel,
    ));
  }

  /// Create a copy of ReadingInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReadingInfoSectionModelCopyWith<$Res> get header {
    return $ReadingInfoSectionModelCopyWith<$Res>(_self.header, (value) {
      return _then(_self.copyWith(header: value));
    });
  }

  /// Create a copy of ReadingInfoModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReadingInfoSectionModelCopyWith<$Res> get footer {
    return $ReadingInfoSectionModelCopyWith<$Res>(_self.footer, (value) {
      return _then(_self.copyWith(footer: value));
    });
  }
}

// dart format on
