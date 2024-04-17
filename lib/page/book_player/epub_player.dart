import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class EpubPlayer extends StatefulWidget {
  final String content;
  final Function showOrHideAppBarAndBottomBar;

  EpubPlayer(
      {Key? key,
      required this.content,
      required this.showOrHideAppBarAndBottomBar})
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
        toc = JSON.stringify(toc);
        window.flutter_inappwebview.callHandler('getToc', toc);
      }
      getToc();
      ''');
    return toc;
  }

  void progressSetter() {
    _webViewController.addJavaScriptHandler(
        handlerName: 'getProgress',
        callback: (args) {
          progress = (args[0] as num).toDouble();
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
          BookStyle bookStyle = SharedPreferencesProvider().bookStyle;
          changeStyle(bookStyle);
          ReadTheme readTheme = SharedPreferencesProvider().readTheme;
          changeTheme(readTheme);
        });
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InAppWebView(
            initialSettings: InAppWebViewSettings(),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              _renderPage();
              progressSetter();
            },
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    prevPage();
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    // Show or hide your AppBar and BottomBar here
                    widget.showOrHideAppBarAndBottomBar(true);
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    nextPage();
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void prevPage() {
    widget.showOrHideAppBarAndBottomBar(false);
    _webViewController.evaluateJavascript(source: 'rendition.prev()');
  }

  void nextPage() {
    widget.showOrHideAppBarAndBottomBar(false);
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

  void goToPersentage(double value) {
    _webViewController.evaluateJavascript(source: '''
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
        rendition.themes.default({
          'html': {
            'background-color': '#$backgroundColor',
            'color': '#$textColor',
          },
        }); 
      }
      changeTheme();
      ''');
  }

  void changeStyle(BookStyle bookStyle) {
    _webViewController.evaluateJavascript(source: '''
    changeStyle = function() {
      rendition.themes.fontSize('${bookStyle.fontSize}%');
      rendition.themes.font('${bookStyle.fontFamily}');

      rendition.themes.default({
        'body': {
          'padding-top': '${bookStyle.topMargin}px !important',
          'padding-bottom': '${bookStyle.bottomMargin}px !important',
          'line-height': '${bookStyle.lineHeight} !important',
          'letter-spacing': '${bookStyle.letterSpacing}px !important',
          'word-spacing': '${bookStyle.wordSpacing}px !important',
        },
        'p': {
          'padding-top': '${bookStyle.paragraphSpacing}px !important',
          'line-height': '${bookStyle.lineHeight} !important',
        },
      });
    }
    changeStyle();
  ''');
  }
}
