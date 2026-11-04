import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Keeps the reader and companion mounted in the same slots at every width.
/// Changing presentation changes constraints, never the reading WebView.
class ReadingWorkspaceHost extends StatelessWidget {
  const ReadingWorkspaceHost({
    super.key,
    required this.reader,
    required this.panel,
    required this.visible,
    required this.expanded,
    this.atBottom = false,
    this.panelWidth = 0,
    this.panelHeight = 280,
    this.onResize,
  });

  final Widget reader;
  final Widget panel;
  final bool visible;
  final bool expanded;
  final bool atBottom;
  final double panelWidth;
  final double panelHeight;
  final ValueChanged<double>? onResize;

  static bool usesSplit(double width) => width >= 840;

  static double effectiveWidth(double width, double preferred) =>
      (preferred > 0 ? preferred : width * .4)
          .clamp(360.0, math.min(520.0, width - 400));

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = usesSplit(constraints.maxWidth);
          final keyboard = MediaQuery.viewInsetsOf(context).bottom;
          final availableHeight =
              math.max(0.0, constraints.maxHeight - keyboard);
          final width = wide && !atBottom
              ? effectiveWidth(constraints.maxWidth, panelWidth)
              : constraints.maxWidth;
          final height = wide
              ? atBottom
                  ? math.min(
                      availableHeight,
                      panelHeight
                          .clamp(200.0, math.max(200.0, availableHeight - 320))
                          .toDouble())
                  : availableHeight
              : availableHeight * (expanded || keyboard > 0 ? 1 : .56);
          return Stack(
            children: [
              Positioned.fill(
                right: visible && wide && !atBottom ? width : 0,
                bottom: visible && wide && atBottom ? height + keyboard : 0,
                child: reader,
              ),
              Positioned(
                right: 0,
                bottom: keyboard,
                width: width,
                height: height,
                child: Offstage(
                  offstage: !visible,
                  child: TickerMode(
                    enabled: visible,
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      elevation: wide ? 0 : 8,
                      child: SafeArea(
                        top: !wide && (expanded || keyboard > 0),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: wide && !atBottom ? 1 : 0,
                            top: !wide || atBottom ? 1 : 0,
                          ),
                          child: panel,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (visible && wide)
                Positioned(
                  right: atBottom ? 0 : width - 4,
                  bottom: atBottom ? height + keyboard - 4 : keyboard,
                  width: atBottom ? constraints.maxWidth : 8,
                  height: atBottom ? 8 : height,
                  child: MouseRegion(
                    cursor: atBottom
                        ? SystemMouseCursors.resizeRow
                        : SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: onResize == null
                          ? null
                          : (details) => onResize!(
                              atBottom ? -details.delta.dy : -details.delta.dx),
                      child: Center(
                        child: atBottom
                            ? const Divider(height: 1)
                            : const VerticalDivider(width: 1),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
}
