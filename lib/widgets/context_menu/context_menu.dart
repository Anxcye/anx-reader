import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/widgets/context_menu/excerpt_menu.dart';
import 'package:anx_reader/widgets/context_menu/translation_menu.dart';
import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

void showContextMenu(
  BuildContext context,
  double x,
  double y,
  String dir,
  String annoContent,
  String annoCfi,
  int? annoId,
  bool footnote,
) {
  final playerKey = epubPlayerKey.currentState!;
  double screenWidth = MediaQuery.of(context).size.width;
  double screenHeight = MediaQuery.of(context).size.height;

  double menuWidth = 370 > screenWidth ? screenWidth - 20 : 350;
  x *= screenWidth;
  y *= screenHeight;

  double widgetLeft =
      x + menuWidth > screenWidth ? screenWidth - menuWidth - 20 : x;

  playerKey.removeOverlay();

  void onClose() {
    playerKey.webViewController.evaluateJavascript(source: 'clearSelection()');
    playerKey.removeOverlay();
  }

  BoxDecoration decoration = BoxDecoration(
    color: Theme.of(context).colorScheme.secondaryContainer,
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        spreadRadius: 5,
        blurRadius: 7,
        offset: const Offset(0, 3),
      ),
    ],
  );

  bool showTranslationMenu = Prefs().autoTranslateSelection;

  double bottomPosition =
      y > 350 ? (screenHeight - y + 20) : screenHeight - 370;

  double topPosition = screenHeight - y > 350 ? y + 20 : screenHeight - 350;

  playerKey.contextMenuEntry = OverlayEntry(builder: (context) {
    return Positioned(
      left: widgetLeft,
      bottom: dir == "up" ? bottomPosition : null,
      top: dir != "up" ? topPosition : null,
      child: Container(
        width: menuWidth,
        // height: menuHeight,
        color: Colors.transparent,
        child: StatefulBuilder(builder: (context, setState) {
          void toggleTranslationMenu() {
            setState(() {
              showTranslationMenu = !showTranslationMenu;
            });
          }

          return PointerInterceptor(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  double bottom =
                      bottomPosition > MediaQuery.of(context).viewInsets.bottom
                          ? 0
                          : MediaQuery.of(context).viewInsets.bottom -
                              bottomPosition;
                  return Column(
                    children: [
                      Row(
                        children: [
                          ExcerptMenu(
                            annoCfi: annoCfi,
                            annoContent: annoContent,
                            id: annoId,
                            onClose: onClose,
                            footnote: footnote,
                            decoration: decoration,
                            toggleTranslationMenu: toggleTranslationMenu,
                          ),
                        ],
                      ),
                      SizedBox(height: bottom),
                    ],
                  );
                }),
                const SizedBox(height: 10),
                if (showTranslationMenu)
                  Row(
                    children: [
                      TranslationMenu(
                        content: annoContent,
                        decoration: decoration,
                      ),
                    ],
                  ),
              ],
            ),
          );
        }),
      ),
    );
  });

  Overlay.of(context).insert(playerKey.contextMenuEntry!);
}
