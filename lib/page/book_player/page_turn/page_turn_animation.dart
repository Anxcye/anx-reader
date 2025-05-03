import 'package:flutter/material.dart';

abstract class PageTurnAnimation {
  bool isPageTurning = false;
  bool turnedPage = false;
  double position = 0;
  Widget? preparedImage;
  Widget? currentImage;
  bool showAnimationScreen = false;
  double webviewPosition = 0;

  void onDragStart(DragStartDetails details);
  void onDragUpdate(DragUpdateDetails details, BuildContext context);
  Future<void> onDragEnd(DragEndDetails details, BuildContext context, Function(void Function()) setState);
  Widget buildAnimationWidget(BuildContext context);
  double getWebViewPosition() => webviewPosition;
  
  void reset() {
    isPageTurning = false;
    turnedPage = false;
    position = 0;
    webviewPosition = 0;
    showAnimationScreen = false;
    currentImage = null;
  }

  void updatePreparedImage(Widget image) {
    preparedImage = image;
  }
} 