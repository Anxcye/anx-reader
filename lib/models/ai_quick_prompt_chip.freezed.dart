// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_quick_prompt_chip.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AiQuickPromptChip {
  IconData get icon;
  String get label;
  String get prompt;

  /// Create a copy of AiQuickPromptChip
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AiQuickPromptChipCopyWith<AiQuickPromptChip> get copyWith =>
      _$AiQuickPromptChipCopyWithImpl<AiQuickPromptChip>(
          this as AiQuickPromptChip, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AiQuickPromptChip &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.prompt, prompt) || other.prompt == prompt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, icon, label, prompt);

  @override
  String toString() {
    return 'AiQuickPromptChip(icon: $icon, label: $label, prompt: $prompt)';
  }
}

/// @nodoc
abstract mixin class $AiQuickPromptChipCopyWith<$Res> {
  factory $AiQuickPromptChipCopyWith(
          AiQuickPromptChip value, $Res Function(AiQuickPromptChip) _then) =
      _$AiQuickPromptChipCopyWithImpl;
  @useResult
  $Res call({IconData icon, String label, String prompt});
}

/// @nodoc
class _$AiQuickPromptChipCopyWithImpl<$Res>
    implements $AiQuickPromptChipCopyWith<$Res> {
  _$AiQuickPromptChipCopyWithImpl(this._self, this._then);

  final AiQuickPromptChip _self;
  final $Res Function(AiQuickPromptChip) _then;

  /// Create a copy of AiQuickPromptChip
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? icon = null,
    Object? label = null,
    Object? prompt = null,
  }) {
    return _then(_self.copyWith(
      icon: null == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as IconData,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      prompt: null == prompt
          ? _self.prompt
          : prompt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _AiQuickPromptChip implements AiQuickPromptChip {
  const _AiQuickPromptChip(
      {required this.icon, required this.label, required this.prompt});

  @override
  final IconData icon;
  @override
  final String label;
  @override
  final String prompt;

  /// Create a copy of AiQuickPromptChip
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AiQuickPromptChipCopyWith<_AiQuickPromptChip> get copyWith =>
      __$AiQuickPromptChipCopyWithImpl<_AiQuickPromptChip>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AiQuickPromptChip &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.prompt, prompt) || other.prompt == prompt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, icon, label, prompt);

  @override
  String toString() {
    return 'AiQuickPromptChip(icon: $icon, label: $label, prompt: $prompt)';
  }
}

/// @nodoc
abstract mixin class _$AiQuickPromptChipCopyWith<$Res>
    implements $AiQuickPromptChipCopyWith<$Res> {
  factory _$AiQuickPromptChipCopyWith(
          _AiQuickPromptChip value, $Res Function(_AiQuickPromptChip) _then) =
      __$AiQuickPromptChipCopyWithImpl;
  @override
  @useResult
  $Res call({IconData icon, String label, String prompt});
}

/// @nodoc
class __$AiQuickPromptChipCopyWithImpl<$Res>
    implements _$AiQuickPromptChipCopyWith<$Res> {
  __$AiQuickPromptChipCopyWithImpl(this._self, this._then);

  final _AiQuickPromptChip _self;
  final $Res Function(_AiQuickPromptChip) _then;

  /// Create a copy of AiQuickPromptChip
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? icon = null,
    Object? label = null,
    Object? prompt = null,
  }) {
    return _then(_AiQuickPromptChip(
      icon: null == icon
          ? _self.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as IconData,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      prompt: null == prompt
          ? _self.prompt
          : prompt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
