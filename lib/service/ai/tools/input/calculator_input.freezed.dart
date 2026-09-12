// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calculator_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CalculatorInput {
  String? get expression;

  /// Create a copy of CalculatorInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CalculatorInputCopyWith<CalculatorInput> get copyWith =>
      _$CalculatorInputCopyWithImpl<CalculatorInput>(
          this as CalculatorInput, _$identity);

  /// Serializes this CalculatorInput to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CalculatorInput &&
            (identical(other.expression, expression) ||
                other.expression == expression));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, expression);

  @override
  String toString() {
    return 'CalculatorInput(expression: $expression)';
  }
}

/// @nodoc
abstract mixin class $CalculatorInputCopyWith<$Res> {
  factory $CalculatorInputCopyWith(
          CalculatorInput value, $Res Function(CalculatorInput) _then) =
      _$CalculatorInputCopyWithImpl;
  @useResult
  $Res call({String? expression});
}

/// @nodoc
class _$CalculatorInputCopyWithImpl<$Res>
    implements $CalculatorInputCopyWith<$Res> {
  _$CalculatorInputCopyWithImpl(this._self, this._then);

  final CalculatorInput _self;
  final $Res Function(CalculatorInput) _then;

  /// Create a copy of CalculatorInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? expression = freezed,
  }) {
    return _then(_self.copyWith(
      expression: freezed == expression
          ? _self.expression
          : expression // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _CalculatorInput extends CalculatorInput {
  const _CalculatorInput({this.expression}) : super._();
  factory _CalculatorInput.fromJson(Map<String, dynamic> json) =>
      _$CalculatorInputFromJson(json);

  @override
  final String? expression;

  /// Create a copy of CalculatorInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CalculatorInputCopyWith<_CalculatorInput> get copyWith =>
      __$CalculatorInputCopyWithImpl<_CalculatorInput>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CalculatorInputToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CalculatorInput &&
            (identical(other.expression, expression) ||
                other.expression == expression));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, expression);

  @override
  String toString() {
    return 'CalculatorInput(expression: $expression)';
  }
}

/// @nodoc
abstract mixin class _$CalculatorInputCopyWith<$Res>
    implements $CalculatorInputCopyWith<$Res> {
  factory _$CalculatorInputCopyWith(
          _CalculatorInput value, $Res Function(_CalculatorInput) _then) =
      __$CalculatorInputCopyWithImpl;
  @override
  @useResult
  $Res call({String? expression});
}

/// @nodoc
class __$CalculatorInputCopyWithImpl<$Res>
    implements _$CalculatorInputCopyWith<$Res> {
  __$CalculatorInputCopyWithImpl(this._self, this._then);

  final _CalculatorInput _self;
  final $Res Function(_CalculatorInput) _then;

  /// Create a copy of CalculatorInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? expression = freezed,
  }) {
    return _then(_CalculatorInput(
      expression: freezed == expression
          ? _self.expression
          : expression // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
