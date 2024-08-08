import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/widgets/excerpt_menu.dart';
import 'package:flutter/material.dart';

void showContextMenu(
    BuildContext context,
    double x,
    double y,
    String dir,
    String annoContent,
    String annoCfi,
    int? annoId,
    ) {

  final playerKey = epubPlayerKey.currentState!;
  double menuWidth = 350;
  double menuHeight = 100;
  double screenWidth = MediaQuery.of(context).size.width;
  double screenHeight = MediaQuery.of(context).size.height;
  x *= screenWidth;
  y *= screenHeight;
  
  double widgetTop = dir == "up" ? y - menuHeight - 20 : y + 20;
  double widgetLeft = x + menuWidth > screenWidth
      ? screenWidth - menuWidth - 20
      : x;

  y = y > 80 ? y - 80 : y;

  playerKey.removeOverlay();

  void onClose() {
    playerKey.webViewController.evaluateJavascript(source: 'clearSelection()');
    playerKey.removeOverlay();
  }

  playerKey.contextMenuEntry = OverlayEntry(builder: (context) {
    return Positioned(
      left: widgetLeft,
      top: widgetTop,
      child: Container(
        width: menuWidth,
        height: menuHeight,
        color: Colors.transparent,
        child: Column(
          children: [
            excerptMenu(
              context,
              annoCfi,
              annoContent,
              annoId,
              onClose,
            ),
          ],
        ),
      ),
    );
  });

  Overlay.of(context).insert(playerKey.contextMenuEntry!);
}
