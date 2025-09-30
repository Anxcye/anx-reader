import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/widgets/common/container/outlined_container.dart';
import 'package:flutter/material.dart';

class FilledContainer extends StatelessWidget {
  const FilledContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
    this.radius,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    if (Prefs().eInkMode) {
      return OutlinedContainer(
        radius: radius,
        padding: padding ,
        margin: margin,
        width: width,
        height: height,
        child: child,
      );
    }
    final Color effectiveColor =
        color ?? Theme.of(context).colorScheme.surfaceContainer;

    return Container(
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: effectiveColor,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadiusGeometry.circular(radius ?? 30),
          side: BorderSide(
            color: Colors.transparent,
            width: 1,
          ),
        ),
      ),
      child: child,
    );
  }
}
