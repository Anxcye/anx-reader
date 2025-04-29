import 'package:flutter/material.dart';
import 'dart:math' as math;

class LinearProportionBar extends StatelessWidget {
  final List<SegmentData> segments;
  final double height;
  final BorderRadius borderRadius;

  const LinearProportionBar({
    super.key,
    required this.segments,
    this.height = 24.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(24.0)),
  });

  @override
  Widget build(BuildContext context) {
    final bool allZero = segments.every((segment) => segment.proportion <= 0);
    final int defaultFlex = allZero ? 1 : 0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Row(
          children: segments.map((segment) {
            return Expanded(
              flex: allZero
                  ? defaultFlex
                  : math.max(0, (segment.proportion * 100).round()),
              child: Container(
                color: segment.color,
                child: Center(
                  child: segment.showLabel
                      ? Text(
                          allZero
                              ? '0%'
                              : ' ${(segment.proportion * 100).round()}% ',
                          style: TextStyle(
                            color: segment.labelColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class SegmentData {
  final double proportion;
  final Color color;
  final bool showLabel;
  final Color labelColor;

  SegmentData({
    required this.proportion,
    required this.color,
    this.showLabel = false,
    this.labelColor = Colors.white,
  });
}
