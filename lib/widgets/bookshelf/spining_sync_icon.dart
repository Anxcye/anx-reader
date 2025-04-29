import 'package:flutter/material.dart';

class SpiningSyncIcon extends StatefulWidget {
  const SpiningSyncIcon({
    super.key,
    this.size = 16,
    this.color = Colors.grey,
  });

  final double size;
  final Color color;

  @override
  State<SpiningSyncIcon> createState() => _SpiningSyncIconState();
}

class _SpiningSyncIconState extends State<SpiningSyncIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: -1.0).animate(_controller),
      child: Center(
        child: Icon(
          Icons.sync,
          color: widget.color,
          size: widget.size,
        ),
      ),
    );
  }
}
