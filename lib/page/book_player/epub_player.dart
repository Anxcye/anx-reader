import 'dart:convert';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/coordinates_to_part.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/widgets/context_menu.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/page_turning/diagram.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/page_turning/types_and_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class EpubPlayer extends StatefulWidget {
  final String content;
  final int bookId;
  final Function showOrHideAppBarAndBottomBar;

  const EpubPlayer(
      {super.key,
      required this.content,
      required this.showOrHideAppBarAndBottomBar,
      required this.bookId});

  @override
  State<EpubPlayer> createState() => EpubPlayerState();
}

class EpubPlayerState extends State<EpubPlayer> {
  late InAppWebViewController webViewController;
  double progress = 0.0;
  int chapterCurrentPage = 0;
  int chapterTotalPage = 0;
  String chapterTitle = '';
  String chapterHref = '';
  late ContextMenu contextMenu;
  OverlayEntry? contextMenuEntry;

  Future<String> onReadingLocation() async {
    String currentCfi = '';
    webViewController.addJavaScriptHandler(
        handlerName: 'onReadingLocation',
        callback: (args) {
          currentCfi = args[0];
        });
    await webViewController.evaluateJavascript(source: '''
      var currentLocation = rendition.currentLocation();
      var currentCfi = currentLocation.start.cfi;
      window.flutter_inappwebview.callHandler('onReadingLocation', currentCfi);
      ''');
    return currentCfi;
  }

  void goTo(String str) {
    webViewController.evaluateJavascript(source: '''
      rendition.display('$str');
      ''');
  }

  Future<String> getToc() async {
    String toc = '';
    webViewController.addJavaScriptHandler(
        handlerName: 'getToc',
        callback: (args) {
          toc = args[0];
        });
    await webViewController.evaluateJavascript(source: '''
     getToc = function() {
       let toc = book.navigation.toc;
     
       function removeSuffix(obj) {
         if (obj.href && obj.href.includes('#')) {
           obj.href = obj.href.split('#')[0];
         }
         if (obj.subitems) {
           obj.subitems.forEach(removeSuffix);
         }
       }
     
       toc = JSON.parse(JSON.stringify(toc));
     
       toc.forEach(removeSuffix);
     
       toc = JSON.stringify(toc);
       window.flutter_inappwebview.callHandler('getToc', toc);
     }
          getToc();
      ''');
    AnxLog.info('BookPlayer: $toc');
    return toc;
  }

  void progressSetter() {
    webViewController.addJavaScriptHandler(
        handlerName: 'getCurrentInfo',
        callback: (args) {
          Map<String, dynamic> currentInfo = args[0];
          if (currentInfo['progress'] == null) {
            return;
          }
          progress = (currentInfo['progress'] as num).toDouble();
          chapterCurrentPage = currentInfo['chapterCurrentPage'];
          chapterTotalPage = currentInfo['chapterTotalPage'];
          chapterTitle = currentInfo['chapterTitle'];
          chapterHref = currentInfo['chapterHref'];
        });
  }

  void clickHandlers() {
    // window.flutter_inappwebview.callHandler('onTap', { x: x, y: y });
    webViewController.addJavaScriptHandler(
        handlerName: 'onTap',
        callback: (args) {
          if (contextMenuEntry != null) {
            removeOverlay();
            return;
          }
          Map<String, dynamic> coordinates = args[0];
          double x = coordinates['x'];
          double y = coordinates['y'];
          onViewerTap(x, y);
        });

    // window.flutter_inappwebview.callHandler('onSelected', { left: left, right: right, top: top, bottom: bottom, cfiRange: selectedCfiRange, text: selectedText });
    webViewController.addJavaScriptHandler(
        handlerName: 'onSelected',
        callback: (args) async {
          Map<String, dynamic> coordinates = args[0];
          final left = coordinates['left'];
          // double right = coordinates['right'];
          final top = coordinates['top'];
          final bottom = coordinates['bottom'];
          final annoCfi = coordinates['cfiRange'];
          if (coordinates['text'] == '') {
            return;
          }
          final annoContent = coordinates['text'];
          int? annoId = coordinates['annoId'];

          final screenSize = MediaQuery.of(context).size;

          final actualLeft = left * screenSize.width;
          final actualTop = top * screenSize.height;
          final actualBottom = bottom * screenSize.height;

          showContextMenu(
            context,
            actualLeft,
            actualTop,
            actualBottom,
            annoContent,
            annoCfi,
            annoId,
          );
        });
    webViewController.addJavaScriptHandler(
        handlerName: 'getAllAnnotations',
        callback: (args) async {
          List<BookNote> annotations =
              await selectBookNotesByBookId(widget.bookId);

          List<String> annotationsJson = annotations
              .map((annotation) => jsonEncode(annotation.toMap()))
              .toList();

          for (String annotationJson in annotationsJson) {
            webViewController.evaluateJavascript(
                source: 'addABookNote($annotationJson);');
          }
        });

    webViewController.addJavaScriptHandler(
        handlerName: 'showMenu',
        callback: (args) async {
          removeOverlay();
          widget.showOrHideAppBarAndBottomBar(true);
        });
  }

  void renderNote(BookNote bookNote) {
    webViewController.evaluateJavascript(source: '''
      addABookNote(${jsonEncode(bookNote.toMap())});
      ''');
  }

  void onViewerTap(double x, double y) {
    int part = coordinatesToPart(x, y);
    int currentPageTurningType = Prefs().pageTurningType;
    List<PageTurningType> pageTurningType =
        pageTurningTypes[currentPageTurningType];
    switch (pageTurningType[part]) {
      case PageTurningType.prev:
        prevPage();
        break;
      case PageTurningType.next:
        nextPage();
        break;
      case PageTurningType.menu:
        widget.showOrHideAppBarAndBottomBar(true);
        break;
    }

    readingPageKey.currentState!.setAwakeTimer(Prefs().awakeTime);
  }

  Future<void> _renderPage() async {
    await webViewController.loadData(
      data: widget.content,
      mimeType: "text/html",
      encoding: "utf8",
    );
  }

  void removeOverlay() {
    if (contextMenuEntry == null || contextMenuEntry?.mounted == false) return;
    contextMenuEntry?.remove();
    contextMenuEntry = null;
  }

  @override
  void initState() {
    super.initState();
    contextMenu = ContextMenu(
      settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
      onCreateContextMenu: (hitTestResult) async {
        webViewController.evaluateJavascript(source: "selectEnd()");
      },
      onHideContextMenu: () {
        removeOverlay();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
    InAppWebViewController.clearAllCache();
    removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InAppWebView(
            initialSettings: InAppWebViewSettings(
              supportZoom: false,
              transparentBackground: true,
            ),
            contextMenu: contextMenu,
            onWebViewCreated: (controller) {
              webViewController = controller;
              _renderPage();
              progressSetter();
              clickHandlers();
            },
            onConsoleMessage: (controller, consoleMessage) {
              if (consoleMessage.messageLevel == ConsoleMessageLevel.LOG) {
                AnxLog.info('Webview: ${consoleMessage.message}');
              } else if (consoleMessage.messageLevel ==
                  ConsoleMessageLevel.WARNING) {
                AnxLog.warning('Webview: ${consoleMessage.message}');
              } else if (consoleMessage.messageLevel ==
                  ConsoleMessageLevel.ERROR) {
                AnxLog.severe('Webview: ${consoleMessage.message}');
              }
            },
          ),
        ],
      ),
    );
  }

  void prevPage() {
    webViewController.evaluateJavascript(source: 'prevPage(viewWidth, 300)');
  }

  void nextPage() {
    webViewController.evaluateJavascript(source: 'nextPage(viewWidth, 300)');
  }

  void prevChapter() {
    webViewController.evaluateJavascript(source: '''
      prevChapter = function() {
        let toc = book.navigation.toc;
        let href = rendition.currentLocation().start.href;
        let chapter = toc.filter(chapter => chapter.href === href)[0];
        let index = toc.indexOf(chapter);
        if (index > 0) {
          rendition.display(toc[index - 1].href);
        }
      }
      prevChapter();
      refreshProgress();
      ''');
  }

  void nextChapter() {
    webViewController.evaluateJavascript(source: '''
    nextChapter = function() {
        let toc = book.navigation.toc;
        let href = rendition.currentLocation().start.href;
        let chapter = toc.filter(chapter => chapter.href === href)[0];
        let index = toc.indexOf(chapter);
        if (index < toc.length - 1) {
          rendition.display(toc[index + 1].href);
        }
      }
      nextChapter();
      refreshProgress();
      ''');
  }

  Future<void> goToPercentage(double value) async {
    await webViewController.evaluateJavascript(source: '''
      goToPercentage = function(value) {
        let location = book.locations.cfiFromPercentage(value);
        rendition.display(location);
      }
      goToPercentage($value);
      refreshProgress();
      
      ''');
  }

  void changeTheme(ReadTheme readTheme) {
    // convert color from AABBGGRR to RRGGBBAA
    String backgroundColor = readTheme.backgroundColor.substring(2) +
        readTheme.backgroundColor.substring(0, 2);
    String textColor =
        readTheme.textColor.substring(2) + readTheme.textColor.substring(0, 2);

    webViewController.evaluateJavascript(source: '''
      changeTheme = function() {
        const body = document.querySelector('body');
        body.style.backgroundColor = '#$backgroundColor';
      
        backgroundColor = '$backgroundColor';
        textColor = '$textColor';
        defaultStyle();
      }
      changeTheme();
      ''');
  }

  void changeStyle(BookStyle bookStyle) {
    webViewController.evaluateJavascript(source: '''
    changeStyle = function() {
      primeStyle = {
          fontSize: ${bookStyle.fontSize},
          fontFamily: '${bookStyle.fontFamily}',
          lineHeight: '${bookStyle.lineHeight}',
          letterSpacing: ${bookStyle.letterSpacing},
          wordSpacing: ${bookStyle.wordSpacing},
          paragraphSpacing: ${bookStyle.paragraphSpacing},
          sideMargin: ${bookStyle.sideMargin},
          topMargin: ${bookStyle.topMargin},
          bottomMargin: ${bookStyle.bottomMargin},
        }
      defaultStyle();
    }
    changeStyle();
    
    rendition.views().forEach(view => {
      if (view.pane) view.pane.render()
    })
    
    setClickEvent();
  ''');
  }
}
