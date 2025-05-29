

import 'package:anx_reader/widgets/page_router/page_dismiss_controller.dart';
import 'package:flutter/material.dart';

class ControlledDismissiblePage extends StatefulWidget {
  final PageDismissController controller;
  final Widget child;

  const ControlledDismissiblePage({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  ControlledDismissiblePageState createState() =>
      ControlledDismissiblePageState();
}

class ControlledDismissiblePageState extends State<ControlledDismissiblePage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdate);
  }

  @override
  void didUpdateWidget(covariant ControlledDismissiblePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerUpdate);
      widget.controller.addListener(_onControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    // The controller itself should be disposed where it's created and managed
    super.dispose();
  }

  void _onControllerUpdate() {
    // Just trigger a rebuild. The transform will use the controller's currentOffset.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: widget.controller.currentOffset,
      child: widget.child,
    );
  }
}
