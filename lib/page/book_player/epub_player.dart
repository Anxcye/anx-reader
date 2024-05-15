import 'dart:convert';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../models/book_note.dart';

class EpubPlayer extends StatefulWidget {
  final String content;
  final int bookId;
  final Function showOrHideAppBarAndBottomBar;

  EpubPlayer(
      {Key? key,
      required this.content,
      required this.showOrHideAppBarAndBottomBar,
      required this.bookId})
      : super(key: key);

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
    print(toc);
    return toc;
  }

  void progressSetter() {
    _webViewController.addJavaScriptHandler(
        handlerName: 'getProgress',
        callback: (args) {
          if (args[0] != null) {
            progress = (args[0] as num).toDouble();
          }
        });

    _webViewController.addJavaScriptHandler(
        handlerName: 'getChapterCurrentPage',
        callback: (args) {
          chapterCurrentPage = args[0];
        });

    _webViewController.addJavaScriptHandler(
        handlerName: 'getChapterTotalPage',
        callback: (args) {
          chapterTotalPage = args[0];
        });
    _webViewController.addJavaScriptHandler(
        handlerName: 'getChapterTitle',
        callback: (args) {
          chapterTitle = args[0];
        });
    _webViewController.addJavaScriptHandler(
        handlerName: 'getChapterHref',
        callback: (args) {
          chapterHref = args[0];
        });
    _webViewController.addJavaScriptHandler(
        handlerName: 'onRelocated',
        callback: (args) {
          BookStyle bookStyle = Prefs().bookStyle;
          changeStyle(bookStyle);
          ReadTheme readTheme = Prefs().readTheme;
          changeTheme(readTheme);
        });
  }

  void clickHandlers() {
    // window.flutter_inappwebview.callHandler('onTap', { x: x, y: y });
    _webViewController.addJavaScriptHandler(
        handlerName: 'onTap',
        callback: (args) {
          print(args[0]);

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
          double right = coordinates['right'];
          double top = coordinates['top'];
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
            int id = await insertBookNote(BookNote(
              bookId: widget.bookId,
              content: annoContent,
              cfi: annoCfi,
              chapter: chapterTitle,
              type: result['type'],
              color: result['color'],
              createTime: DateTime.now(),
              updateTime: DateTime.now(),
            ));
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
            updateBookNoteById(
              BookNote(
                id: id,
                bookId: widget.bookId,
                content: oldNote.content,
                cfi: oldNote.cfi,
                chapter: oldNote.chapter,
                type: result['type'],
                color: result['color'],
                createTime: oldNote.createTime,
                updateTime: DateTime.now(),
              ),
            );
            _webViewController.evaluateJavascript(
                source: 'removeCurrentAnnotations()');
            renderNote(BookNote(
              id: id,
              bookId: widget.bookId,
              content: oldNote.content,
              cfi: oldNote.cfi,
              chapter: oldNote.chapter,
              type: result['type'],
              color: result['color'],
              createTime: oldNote.createTime,
              updateTime: DateTime.now(),
            ));
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
    if (x < 0.3) {
      prevPage();
    } else if (x > 0.7) {
      nextPage();
    } else {
      widget.showOrHideAppBarAndBottomBar(true);
    }
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

            final widgetSize = Size(288.0, 48.0);

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
      required ValueChanged<String> onColorSelected,
      required ValueChanged<String> onTypeSelected}) {
    String annoType = type;
    String annoColor = color;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(children: [
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
        Divider(),
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
    _webViewController.evaluateJavascript(source: 'rendition.prev()');
  }

  void nextPage() {
    _webViewController.evaluateJavascript(source: 'rendition.next()');
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

  Future<void> goToPersentage(double value) async {
    await _webViewController.evaluateJavascript(source: '''
      goToPersentage = function(value) {
        let location = book.locations.cfiFromPercentage(value);
        rendition.display(location);
      }
      goToPersentage($value);
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
      const body = document.querySelector('body');
      
      
      rendition.themes.fontSize('${bookStyle.fontSize}%');
      rendition.themes.font('${bookStyle.fontFamily}');
      
      rendition.themes.default({
        'body': {
          'padding-top': '${bookStyle.topMargin}px !important',
          'padding-bottom': '${bookStyle.bottomMargin}px !important',
          'line-height': '${bookStyle.lineHeight} !important',
          'letter-spacing': '${bookStyle.letterSpacing}px !important',
          // 'word-spacing': '${bookStyle.wordSpacing}px !important',
        },
        'p': {
          'padding-top': '${bookStyle.paragraphSpacing}px !important',
          'line-height': '${bookStyle.lineHeight} !important',
        },
      });
    }
    changeStyle();
    setClickEvent();
  ''');
  }
}
