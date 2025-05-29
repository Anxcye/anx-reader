import 'package:flutter/material.dart';

enum DismissalState { idle, dragging, animatingOut, animatingBack }

class PageDismissController extends ChangeNotifier {
  late AnimationController _animationController;
  late Animation<Offset> _animation;
  final TickerProvider
      vsync; // To be provided by the widget using the controller

  double _currentVerticalOffset = 0.0;
  DismissalState _state = DismissalState.idle;

  final double dismissThreshold; // e.g., 150.0
  final Duration animationDuration;

  get shouldDismiss =>
      _state == DismissalState.dragging &&
      _currentVerticalOffset > dismissThreshold;

  PageDismissController({
    required this.vsync,
    this.dismissThreshold = 150.0, // Default threshold
    this.animationDuration = const Duration(milliseconds: 300),
  }) {
    _animationController = AnimationController(
      vsync: vsync,
      duration: animationDuration,
    );

    // Default animation, target offset will be updated
    _animation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.addListener(() {
      // If animation changes, notify listeners to rebuild
      notifyListeners();
    });
  }

  // Getter for the current offset (combines drag and animation)
  Offset get currentOffset {
    if (_state == DismissalState.dragging) {
      return Offset(0, -_currentVerticalOffset);
    }
    // During animation, _animation.value gives the interpolated offset
    // It's important that the Tween's 'end' is set correctly before animation starts.
    return _animation.value;
  }

  DismissalState get state => _state;

  // Called by an external gesture detector during a drag
  void updateDrag(DragUpdateDetails details) {
    if (_state == DismissalState.animatingOut ||
        _state == DismissalState.animatingBack) {
      return;
    }

    _state = DismissalState.dragging;
    _currentVerticalOffset -=
        details.delta.dy; // Negative delta.dy for upward swipe
    // Clamp the offset if needed, e.g., prevent dragging down too much
    _currentVerticalOffset = _currentVerticalOffset.clamp(0.0, double.infinity);
    notifyListeners();
  }

  // Called by an external gesture detector when a drag ends
  // Returns true if dismissal is triggered, false otherwise.
  Future<bool> endDrag(DragEndDetails details, BuildContext context) async {
    if (_state != DismissalState.dragging) return false;

    final bool shouldDismiss = _currentVerticalOffset > dismissThreshold ||
        (details.velocity.pixelsPerSecond.dy < -500); // Swipe up fast

    if (shouldDismiss) {
      _state = DismissalState.animatingOut;
      _animation = Tween<Offset>(
        begin: Offset(
            0, -_currentVerticalOffset), // Start from current drag position
        end: Offset(
            0, -_currentVerticalOffset - 400), // Animate fully off screen
      ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

      // await _animationController.forward(from: 0.3); // Reset and play
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
        _resetStateAfterPop();
        return true;
      }
    } else {
      _state = DismissalState.animatingBack;
      _animation = Tween<Offset>(
        begin: Offset(
            0, -_currentVerticalOffset), // Start from current drag position
        end: Offset.zero, // Animate back to original position
      ).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
      await _animationController.forward(from: 0.0);
    }
    _state = DismissalState.idle;
    _currentVerticalOffset = 0.0; // Reset drag offset after animation
    notifyListeners(); // Notify to reflect final position if not popped
    return false;
  }

  void _resetStateAfterPop() {
    _state = DismissalState.idle;
    _currentVerticalOffset = 0.0;
    _animationController.reset();
    // Don't notifyListeners here if the widget is already disposed after pop
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

