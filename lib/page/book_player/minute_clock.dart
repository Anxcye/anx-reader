import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget that displays the current time in 'HH:mm' format.
class MinuteClock extends StatefulWidget {
  const MinuteClock({
    super.key,
    this.textStyle,
  });

  /// The optional style to apply to the time text.
  final TextStyle? textStyle;

  @override
  State<MinuteClock> createState() => _MinuteClockState();
}

class _MinuteClockState extends State<MinuteClock> {
  String _currentTime = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = _formatDateTime(DateTime.now());

    _scheduleNextUpdate();
  }

  void _scheduleNextUpdate() {
    final secondsUntilNextMinute = 60 - DateTime.now().second;

    // Wait for that initial delay before starting the periodic timer.
    Future.delayed(Duration(seconds: secondsUntilNextMinute), () {
      if (mounted) {
        // The first synchronized update.
        setState(() {
          _currentTime = _formatDateTime(DateTime.now());
        });

        // Start a periodic timer that fires once every minute thereafter.
        _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
          setState(() {
            _currentTime = _formatDateTime(DateTime.now());
          });
        });
      }
    });
  }

  /// Formats the [DateTime] to a 'HH:mm' string.
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentTime,
      style: widget.textStyle,
    );
  }
}
