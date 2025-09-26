import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/widgets/container/outlined_container.dart';
import 'package:flutter/material.dart';

class FilledContainer extends StatelessWidget {
  const FilledContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.only(bottom: 8.0),
    this.color,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (Prefs().eInkMode) {
      return OutlinedContainer(
        padding: padding,
        margin: margin,
        width: width,
        height: height,
        child: child,
      );
    }
    final Color effectiveColor =
        color ?? Theme.of(context).colorScheme.surfaceContainer;

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: effectiveColor,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadiusGeometry.circular(30),
          side: BorderSide(
            color: effectiveColor, 
            width: 2, 
          ),
        ),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
