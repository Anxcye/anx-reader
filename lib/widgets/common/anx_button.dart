import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Visual variants for [AnxButton].
///
/// Existing values ([filled], [outlined], [text]) stay stable for call sites.
/// Newer values map 1:1 onto Forui [FButtonVariant]s.
enum AnxButtonType {
  /// Forui primary (was Material [FilledButton]).
  filled,

  /// Forui outline (was Material [OutlinedButton]).
  outlined,

  /// Forui ghost (was Material [TextButton]).
  text,

  /// Forui secondary.
  secondary,

  /// Forui destructive.
  destructive,

  /// Explicit ghost alias (same as [text]).
  ghost,
}

/// App-facing button facade backed by Forui [FButton].
///
/// Keep using [AnxButton] at call sites — do not depend on raw Material or
/// Forui button widgets so the visual system can be swapped later.
class AnxButton extends StatelessWidget {
  const AnxButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.disabled = false,
    this.isLoading = false,
    this.type = AnxButtonType.filled,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
  })  : icon = null,
        label = null;

  const AnxButton.icon({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.disabled = false,
    this.isLoading = false,
    this.type = AnxButtonType.filled,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
  }) : child = null;

  const AnxButton.text({
    super.key,
    required this.onPressed,
    required this.child,
    this.disabled = false,
    this.isLoading = false,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
  })  : icon = null,
        label = null,
        type = AnxButtonType.text;

  const AnxButton.outlined({
    super.key,
    required this.onPressed,
    required this.child,
    this.disabled = false,
    this.isLoading = false,
    this.style,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
  })  : icon = null,
        label = null,
        type = AnxButtonType.outlined;

  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHover;
  final ValueChanged<bool>? onFocusChange;

  /// Kept for API stability with older Material call sites. Unused by Forui.
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Kept for API stability. Unused by Forui [FButton].
  final Clip clipBehavior;
  final Widget? child;
  final Widget? icon;
  final Widget? label;
  final bool disabled;
  final bool isLoading;
  final AnxButtonType type;

  FButtonVariant get _variant => switch (type) {
        AnxButtonType.filled => FButtonVariant.primary,
        AnxButtonType.outlined => FButtonVariant.outline,
        AnxButtonType.text || AnxButtonType.ghost => FButtonVariant.ghost,
        AnxButtonType.secondary => FButtonVariant.secondary,
        AnxButtonType.destructive => FButtonVariant.destructive,
      };

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed =
        (disabled || isLoading) ? null : onPressed;
    final effectiveOnLongPress =
        (disabled || isLoading) ? null : onLongPress;

    final loading = SizedBox(
      width: 18,
      height: 18,
      child: const FCircularProgress(size: FCircularProgressSizeVariant.sm),
    );

    if (icon != null && label != null) {
      return FButton(
        variant: _variant,
        onPress: effectiveOnPressed,
        onLongPress: effectiveOnLongPress,
        onHoverChange: onHover,
        onFocusChange: onFocusChange,
        focusNode: focusNode,
        autofocus: autofocus,
        mainAxisSize: MainAxisSize.min,
        prefix: isLoading ? loading : icon,
        child: label!,
      );
    }

    return FButton(
      variant: _variant,
      onPress: effectiveOnPressed,
      onLongPress: effectiveOnLongPress,
      onHoverChange: onHover,
      onFocusChange: onFocusChange,
      focusNode: focusNode,
      autofocus: autofocus,
      mainAxisSize: MainAxisSize.min,
      child: isLoading ? loading : (child ?? const SizedBox.shrink()),
    );
  }
}
