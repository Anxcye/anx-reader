// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'current_time_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CurrentTimeInput {
  bool get includeTimezone;

  /// Create a copy of CurrentTimeInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CurrentTimeInputCopyWith<CurrentTimeInput> get copyWith =>
      _$CurrentTimeInputCopyWithImpl<CurrentTimeInput>(
          this as CurrentTimeInput, _$identity);

  /// Serializes this CurrentTimeInput to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CurrentTimeInput &&
            (identical(other.includeTimezone, includeTimezone) ||
                other.includeTimezone == includeTimezone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, includeTimezone);

  @override
  String toString() {
    return 'CurrentTimeInput(includeTimezone: $includeTimezone)';
  }
}

/// @nodoc
abstract mixin class $CurrentTimeInputCopyWith<$Res> {
  factory $CurrentTimeInputCopyWith(
          CurrentTimeInput value, $Res Function(CurrentTimeInput) _then) =
      _$CurrentTimeInputCopyWithImpl;
  @useResult
  $Res call({bool includeTimezone});
}

/// @nodoc
class _$CurrentTimeInputCopyWithImpl<$Res>
    implements $CurrentTimeInputCopyWith<$Res> {
  _$CurrentTimeInputCopyWithImpl(this._self, this._then);

  final CurrentTimeInput _self;
  final $Res Function(CurrentTimeInput) _then;

  /// Create a copy of CurrentTimeInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? includeTimezone = null,
  }) {
    return _then(_self.copyWith(
      includeTimezone: null == includeTimezone
          ? _self.includeTimezone
          : includeTimezone // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _CurrentTimeInput extends CurrentTimeInput {
  const _CurrentTimeInput({this.includeTimezone = true}) : super._();
  factory _CurrentTimeInput.fromJson(Map<String, dynamic> json) =>
      _$CurrentTimeInputFromJson(json);

  @override
  @JsonKey()
  final bool includeTimezone;

  /// Create a copy of CurrentTimeInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CurrentTimeInputCopyWith<_CurrentTimeInput> get copyWith =>
      __$CurrentTimeInputCopyWithImpl<_CurrentTimeInput>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CurrentTimeInputToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CurrentTimeInput &&
            (identical(other.includeTimezone, includeTimezone) ||
                other.includeTimezone == includeTimezone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, includeTimezone);

  @override
  String toString() {
    return 'CurrentTimeInput(includeTimezone: $includeTimezone)';
  }
}

/// @nodoc
abstract mixin class _$CurrentTimeInputCopyWith<$Res>
    implements $CurrentTimeInputCopyWith<$Res> {
  factory _$CurrentTimeInputCopyWith(
          _CurrentTimeInput value, $Res Function(_CurrentTimeInput) _then) =
      __$CurrentTimeInputCopyWithImpl;
  @override
  @useResult
  $Res call({bool includeTimezone});
}

/// @nodoc
class __$CurrentTimeInputCopyWithImpl<$Res>
    implements _$CurrentTimeInputCopyWith<$Res> {
  __$CurrentTimeInputCopyWithImpl(this._self, this._then);

  final _CurrentTimeInput _self;
  final $Res Function(_CurrentTimeInput) _then;

  /// Create a copy of CurrentTimeInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? includeTimezone = null,
  }) {
    return _then(_CurrentTimeInput(
      includeTimezone: null == includeTimezone
          ? _self.includeTimezone
          : includeTimezone // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
