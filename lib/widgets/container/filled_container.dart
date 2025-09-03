import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/widgets/container/outlined_container.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';

class FilledContainer extends StatelessWidget {
  const FilledContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.only(bottom: 8.0),
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

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

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius(
            cornerRadius: 20,
            cornerSmoothing: 0.8,
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
