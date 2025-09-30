import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/widgets/common/container/base_rounded_container.dart';
import 'package:anx_reader/widgets/common/container/outlined_container.dart';
import 'package:flutter/material.dart';

class FilledContainer extends BaseRoundedContainer {
  const FilledContainer({
    super.key,
    required super.child,
    super.width,
    super.height,
    super.padding,
    super.margin,
    this.color,
    super.radius,
  });

  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (Prefs().eInkMode) {
      return OutlinedContainer(
        child: child,
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        radius: radius,
      );
    }

    return super.build(context);
  }

  @override
  ShapeDecoration decoration(
    BuildContext context,
    BorderRadiusGeometry borderRadius,
  ) {
    final Color effectiveColor =
        color ?? Theme.of(context).colorScheme.surfaceContainer;

    return buildShapeDecoration(
      color: effectiveColor,
      borderSide: const BorderSide(
        color: Colors.transparent,
        width: 1,
      ),
      borderRadius: borderRadius,
    );
  }
}
