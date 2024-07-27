import 'dart:convert';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/coordiantes_to_part.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/page_turning/diagram.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/page_turning/types_and_icons.dart';
import 'package:flutter/cupertino.dart';
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
  late InAppWebViewController _webViewController;
  double progress = 0.0;
  int chapterCurrentPage = 0;
  int chapterTotalPage = 0;
  String chapterTitle = '';
  String chapterHref = '';
  late ContextMenu contextMenu;
  String selectedColor = '66ccff';
  String selectedType = 'highlight';

  @override
  void dispose() {
    super.dispose();
    InAppWebViewController.clearAllCache();
  }

  Future<String> onReadingLocation() async {
    String currentCfi = '';
    _webViewController.addJavaScriptHandler(
        handlerName: 'onReadingLocation',
        callback: (args) {
          currentCfi = args[0];
        });
    await _webViewController.evaluateJavascript(source: '''
      var currentLocation = rendition.currentLocation();
      var currentCfi = currentLocation.start.cfi;
      window.flutter_inappwebview.callHandler('onReadingLocation', currentCfi);
      ''');
    return currentCfi;
  }

  void goTo(String str) {
    _webViewController.evaluateJavascript(source: '''
      rendition.display('$str');
      ''');
  }

  Future<String> getToc() async {
    String toc = '';
    _webViewController.addJavaScriptHandler(
        handlerName: 'getToc',
        callback: (args) {
          toc = args[0];
        });
    await _webViewController.evaluateJavascript(source: '''
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
    _webViewController.addJavaScriptHandler(
        handlerName: 'getCurrentInfo',
        callback: (args) {
          Map<String, dynamic> currentInfo = args[0];
          progress = (currentInfo['progress'] as num).toDouble();
          chapterCurrentPage = currentInfo['chapterCurrentPage'];
          chapterTotalPage = currentInfo['chapterTotalPage'];
          chapterTitle = currentInfo['chapterTitle'];
          chapterHref = currentInfo['chapterHref'];
        });

    // _webViewController.addJavaScriptHandler(
    //     handlerName: 'onRelocated',
    //     callback: (args) {
    //       // BookStyle bookStyle = Prefs().bookStyle;
    //       // changeStyle(bookStyle);
    //       // ReadTheme readTheme = Prefs().readTheme;
    //       // changeTheme(readTheme);
    //     });
  }

  void clickHandlers() {
    // window.flutter_inappwebview.callHandler('onTap', { x: x, y: y });
    _webViewController.addJavaScriptHandler(
        handlerName: 'onTap',
        callback: (args) {
          Map<String, dynamic> coordinates = args[0];
          double x = coordinates['x'];
          double y = coordinates['y'];
          onViewerTap(x, y);
        });

    // window.flutter_inappwebview.callHandler('onSelected', { left: left, right: right, top: top, bottom: bottom, cfiRange: selectedCfiRange, text: selectedText });
    _webViewController.addJavaScriptHandler(
        handlerName: 'onSelected',
        callback: (args) async {
          Map<String, dynamic> coordinates = args[0];
          double left = coordinates['left'];
          // double right = coordinates['right'];
          // double top = coordinates['top'];
          double bottom = coordinates['bottom'];
          String annoCfi = coordinates['cfiRange'];
          String annoContent = coordinates['text'];

          Size screenSize = MediaQuery.of(context).size;

          double actualLeft = left * screenSize.width;
          double actualBottom = bottom * screenSize.height;

          Offset colorMenuPosition = Offset(actualLeft, actualBottom);
          // setState(() {
          //   isColorMenuVisible = true;
          // });
          Map<String, dynamic>? result =
              await showColorAndTypeSelection(context, colorMenuPosition);
          if (result != null) {
            BookNote bookNote = BookNote(
              bookId: widget.bookId,
              content: annoContent,
              cfi: annoCfi,
              chapter: chapterTitle,
              type: result['type'],
              color: result['color'],
              createTime: DateTime.now(),
              updateTime: DateTime.now(),
            );
            int id = await insertBookNote(bookNote);
            renderNote(BookNote(
              id: id,
              bookId: widget.bookId,
              content: annoContent,
              cfi: annoCfi,
              chapter: chapterTitle,
              type: result['type'],
              color: result['color'],
              createTime: DateTime.now(),
              updateTime: DateTime.now(),
            ));
          }
        });
    _webViewController.addJavaScriptHandler(
        handlerName: 'getAllAnnotations',
        callback: (args) async {
          List<BookNote> annotations =
              await selectBookNotesByBookId(widget.bookId);

          List<String> annotationsJson = annotations
              .map((annotation) => jsonEncode(annotation.toMap()))
              .toList();

          for (String annotationJson in annotationsJson) {
            _webViewController.evaluateJavascript(
                source: 'addABookNote($annotationJson);');
          }
        });
    _webViewController.addJavaScriptHandler(
        handlerName: 'onAnnotationClicked',
        callback: (args) async {
          Map<String, dynamic> coordinates = args[0];
          Size screenSize = MediaQuery.of(context).size;
          double x = coordinates['x'] * screenSize.width;
          double y = coordinates['y'] * screenSize.height;
          int id = coordinates['id'];
          Offset colorMenuPosition = Offset(x, y);

          Map<String, dynamic>? result =
              await showColorAndTypeSelection(context, colorMenuPosition);
          BookNote oldNote = await selectBookNoteById(id);
          if (result != null) {
            if (result['isDelete']) {
              deleteBookNoteById(id);
              _webViewController.evaluateJavascript(
                  source:
                      'removeAnnotations("${oldNote.cfi}", "${oldNote.type}")');
              return;
            }
            BookNote newNote = BookNote(
              id: id,
              bookId: widget.bookId,
              content: oldNote.content,
              cfi: oldNote.cfi,
              chapter: oldNote.chapter,
              type: result['type'],
              color: result['color'],
              createTime: oldNote.createTime,
              updateTime: DateTime.now(),
            );
            updateBookNoteById(newNote);
            _webViewController.evaluateJavascript(
                source:
                    'removeAnnotations("${oldNote.cfi}", "${oldNote.type}")');
            renderNote(newNote);
          }
        });
    _webViewController.addJavaScriptHandler(
        handlerName: 'showMenu',
        callback: (args) async {
          widget.showOrHideAppBarAndBottomBar(true);
        });
  }

  void renderNote(BookNote bookNote) {
    _webViewController.evaluateJavascript(source: '''
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
    await _webViewController.loadData(
      data: widget.content,
      mimeType: "text/html",
      encoding: "utf8",
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    contextMenu = ContextMenu(
      settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
      menuItems: [
        ContextMenuItem(
          id: 1,
          title: context.readingPageCopy,
          action: () async {},
        ),
        ContextMenuItem(
          id: 2,
          title: context.readingPageExcerpt,
          action: () async {
            _webViewController.evaluateJavascript(source: 'excerptHandler()');
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InAppWebView(
            initialSettings: InAppWebViewSettings(),
            contextMenu: contextMenu,
            onWebViewCreated: (controller) {
              _webViewController = controller;
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

  Future<Map<String, dynamic>?> showColorAndTypeSelection(
      BuildContext context, Offset colorMenuPosition) async {
    return await showCupertinoModalPopup<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final screenSize = MediaQuery.of(context).size;

            const widgetSize = Size(288.0, 48.0);

            double dx = colorMenuPosition.dx;
            double dy = colorMenuPosition.dy;
            if (dx < 0) {
              dx = 5;
            }

            if (dx + widgetSize.width > screenSize.width) {
              dx = screenSize.width - widgetSize.width;
            }

            if (dy + widgetSize.height > screenSize.height) {
              dy = screenSize.height - widgetSize.height;
            }

            return Stack(children: [
              Positioned(
                left: dx,
                top: dy,
                child: colorMenuWidget(
                    colorMenuPosition: Offset(dx, dy),
                    color: selectedColor,
                    type: selectedType,
                    onDelete: () {
                      Navigator.pop(context, {
                        'isDelete': true,
                      });
                    },
                    onColorSelected: (color) {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    onTypeSelected: (type) {
                      setState(() {
                        selectedType = type;
                      });
                    },
                    onClose: () {
                      Navigator.pop(context, {
                        'color': selectedColor,
                        'type': selectedType,
                        'isDelete': false,
                      });
                    }),
              ),
            ]);
          },
        );
      },
    );
  }

  Widget colorMenuWidget(
      {required Offset colorMenuPosition,
      required Null Function() onClose,
      required String color,
      required String type,
      required Null Function() onDelete,
      required ValueChanged<String> onColorSelected,
      required ValueChanged<String> onTypeSelected}) {
    String annoType = type;
    String annoColor = color;

    bool deleteConfirm = false;
    Icon deleteIcon() {
      return deleteConfirm
          ? const Icon(
              Icons.delete_forever,
              color: Colors.red,
            )
          : const Icon(Icons.delete);
    }

    void deleteHandler(StateSetter setState) {
      if (deleteConfirm) {
        onDelete();
      } else {
        setState(() {
          deleteConfirm = true;
        });
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(children: [
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return IconButton(
                onPressed: () {
                  deleteHandler(setState);
                },
                icon: deleteIcon());
          },
        ),
        IconButton(
          icon: Icon(
            Icons.format_underline,
            color: annoType == 'underline'
                ? Color(int.parse('0xff$annoColor'))
                : null,
          ),
          onPressed: () {
            onTypeSelected('underline');
          },
        ),
        IconButton(
          icon: Icon(
            Icons.highlight,
            color: annoType == 'highlight'
                ? Color(int.parse('0xff$annoColor'))
                : null,
          ),
          onPressed: () {
            onTypeSelected('highlight');
          },
        ),
        const Divider(),
        IconButton(
          icon: Icon(Icons.circle, color: Color(int.parse('0x8866ccff'))),
          onPressed: () {
            onColorSelected('66ccff');
            onClose();
          },
        ),
        IconButton(
          icon: Icon(Icons.circle, color: Color(int.parse('0x88ff0000'))),
          onPressed: () {
            onColorSelected('ff0000');
            onClose();
          },
        ),
        IconButton(
          icon: Icon(Icons.circle, color: Color(int.parse('0x8800ff00'))),
          onPressed: () {
            onColorSelected('00ff00');
            onClose();
          },
        ),
        IconButton(
          icon: Icon(Icons.circle, color: Color(int.parse('0x88EB3BFF'))),
          onPressed: () {
            onColorSelected('EB3BFF');
            onClose();
          },
        ),
      ]),
    );
  }

  void prevPage() {
    _webViewController.evaluateJavascript(source: 'prevPage(viewWidth, 300)');
  }

  void nextPage() {
    _webViewController.evaluateJavascript(source: 'nextPage(viewWidth, 300)');
  }

  void prevChapter() {
    _webViewController.evaluateJavascript(source: '''
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
    _webViewController.evaluateJavascript(source: '''
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
    await _webViewController.evaluateJavascript(source: '''
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

    _webViewController.evaluateJavascript(source: '''
      changeTheme = function() {
      const body = document.querySelector('body');
      body.style.backgroundColor = '#$backgroundColor';
      body.style.color = '#$textColor'; 
      
        rendition.themes.default({
          'html': {
            'background-color': 'transparent !important',
            'color': '#$textColor !important',
          },
        }); 
      }
      changeTheme();
      ''');
  }

  void changeStyle(BookStyle bookStyle) {
    _webViewController.evaluateJavascript(source: '''
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
    setClickEvent();
  ''');
  }
}
