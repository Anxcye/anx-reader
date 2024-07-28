import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/widgets/excerpt_menu.dart';
import 'package:flutter/material.dart';

void showContextMenu(
    BuildContext context,
    double leftPos,
    double topPos,
    double bottomPos,
    String annoContent,
    String annoCfi,
    int? annoId,
    ) {

  final playerKey = epubPlayerKey.currentState!;
  double menuWidth = 350;
  double menuHeight = 100;
  double screenWidth = MediaQuery.of(context).size.width;
  double screenHeight = MediaQuery.of(context).size.height;
  // space is enough to show the menu in the selection
  double widgetTop = bottomPos - topPos > menuHeight
      ? (topPos + bottomPos - menuHeight) / 2
  // space is not enough to show the menu above the selection
      : topPos < menuHeight + screenHeight / 2
      ? bottomPos + 40
      : topPos - menuHeight - 40;
  double widgetLeft = leftPos + menuWidth > screenWidth
      ? screenWidth - menuWidth - 20
      : leftPos;

  topPos = topPos > 80 ? topPos - 80 : topPos;

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
