import 'package:flutter/material.dart';

class SlideUpDismissRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  SlideUpDismissRoute({required this.child})
      : super(
          opaque: false,
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              child,
        );
}
