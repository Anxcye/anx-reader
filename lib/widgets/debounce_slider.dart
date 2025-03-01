import 'dart:async';
import 'package:flutter/material.dart';

class DebounceSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int divisions;
  final String? label;
  final Color? activeColor;
  final Color? inactiveColor;

  const DebounceSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions = 100,
    this.label,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<DebounceSlider> createState() => _DebounceSliderState();
}

class _DebounceSliderState extends State<DebounceSlider> {
  Timer? _debounceTimer;
  double _currentValue = 0.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleValueChange(double value) {
    setState(() {
      _currentValue = value;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onChanged(value);
      if (widget.onChangeEnd != null) {
        widget.onChangeEnd!(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: _currentValue,
      onChanged: _handleValueChange,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      label: widget.label,
      activeColor: widget.activeColor,
      inactiveColor: widget.inactiveColor,
    );
  }
}
