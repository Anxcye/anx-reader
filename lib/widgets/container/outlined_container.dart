import 'package:flutter/material.dart';

class OutlinedContainer extends StatelessWidget {
  const OutlinedContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      width: width,
      height: height,
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadiusGeometry.circular(30),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
      ),
      child: child,
    );
  }
}
