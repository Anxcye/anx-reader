import 'package:flutter/material.dart';

/// Defines a single segment item used by [AnxSegmentedButton].
class SegmentButtonItem<T> {
  const SegmentButtonItem({
    required this.value,
    required this.label,
    this.icon,
    this.labelStyle,
    this.maxLines,
    this.overflow,
  });

  final T value;
  final String label;
  final Widget? icon;
  final TextStyle? labelStyle;
  final int? maxLines;
  final TextOverflow? overflow;
}

/// A thin wrapper around [SegmentedButton] that accepts [SegmentButtonItem]
/// definitions to keep segment construction consistent across the app.
class AnxSegmentedButton<T> extends StatelessWidget {
  const AnxSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    this.onSelectionChanged,
    this.multiSelectionEnabled = false,
    this.emptySelectionAllowed = false,
    this.showSelectedIcon = true,
    this.style,
  });

  final List<SegmentButtonItem<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;
  final bool multiSelectionEnabled;
  final bool emptySelectionAllowed;
  final bool showSelectedIcon;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: segments
          .map(
            (segment) => ButtonSegment<T>(
              value: segment.value,
              label: Text(
                segment.label,
                style: segment.labelStyle,
                maxLines: segment.maxLines ?? 1,
                overflow: segment.overflow ?? TextOverflow.ellipsis,
              ),
              icon: segment.icon,
            ),
          )
          .toList(),
      selected: selected,
      onSelectionChanged: onSelectionChanged,
      multiSelectionEnabled: multiSelectionEnabled,
      emptySelectionAllowed: emptySelectionAllowed,
      showSelectedIcon: showSelectedIcon,
      style: style,
    );
  }
}
