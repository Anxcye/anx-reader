import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/utils/get_base_path.dart';
import 'package:anx_reader/utils/js/convert_dart_color_to_js.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/import_book.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/webView/webview_console_message.dart';
import 'package:anx_reader/utils/webView/webview_initial_variable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'book_player/book_player_server.dart';

HeadlessInAppWebView? headlessInAppWebView;

Future<void> importBook(File file, Function updateBookList) async {
  AnxToast.show(
      L10n.of(navigatorKey.currentContext!).service_import_n_books(1));
  getBookMetadata(file, updateBookList: updateBookList);
}

void openBook(BuildContext context, Book book, Function updateBookList) {
  book.updateTime = DateTime.now();
  updateBook(book);
  Future.delayed(const Duration(milliseconds: 500), () {
    updateBookList();
  });

  Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ReadingPage(key: readingPageKey, book: book),
      )).then((value) {
    // wait 1s to update book which is read
    Future.delayed(const Duration(milliseconds: 500), () {
      updateBookList();
    });
  });
}

void updateBookRating(Book book, double rating) {
  book.rating = rating;
  updateBook(book);
}

Future<void> resetBookCover(Book book) async {
  File file = File(book.fileFullPath);
  getBookMetadata(file);
}

Future<void> saveBook(
  File file,
  String title,
  String author,
  String description,
  String cover, {
  Book? provideBook,
}) async {
  final newBookName =
      '${title.length > 20 ? title.substring(0, 20) : title}-${DateTime.now().millisecond.toString()}'
          .replaceAll(' ', '_');

  final extension = file.path.split('.').last;

  final relativeFilePath = 'file/$newBookName.$extension';
  final filePath = getBasePath(relativeFilePath);
  String? relativeCoverPath = 'cover/$newBookName';
  // final coverPath = getBasePath(relativeCoverPath);

  await file.copy(filePath);
  relativeCoverPath = await saveImageToLocal(cover, relativeCoverPath);
  Book book = Book(
      id: provideBook != null ? provideBook.id : -1,
      title: title,
      coverPath: relativeCoverPath ?? '',
      filePath: relativeFilePath,
      lastReadPosition: '',
      readingPercentage: 0,
      author: author,
      isDeleted: false,
      rating: 0.0,
      createTime: DateTime.now(),
      updateTime: DateTime.now());

  book.id = await insertBook(book);
  BuildContext context = navigatorKey.currentContext!;
  AnxToast.show(L10n.of(context).service_import_success);
  headlessInAppWebView?.dispose();
  return;
}

Future<void> getBookMetadata(
  File file, {
  Book? book,
  Function? updateBookList,
}) async {
  String filePath = file.path;
  Server().tempFile = file;

  ReadTheme readTheme = Prefs().readTheme;
  String backgroundColor = convertDartColorToJs(readTheme.backgroundColor);
  String textColor = convertDartColorToJs(readTheme.textColor);

  String allAnnotations = 'null';
  String cfi = '';

  String indexHtmlPath =
      "http://localhost:${Server().port}/foliate-js/index.html";

  HeadlessInAppWebView webview = HeadlessInAppWebView(
    initialUrlRequest: URLRequest(url: WebUri(indexHtmlPath)),
    onLoadStart: (controller, url) async {
      controller.evaluateJavascript(
          source: webviewInitialVariable(
        allAnnotations,
        filePath,
        cfi,
        Prefs().bookStyle,
        textColor,
        backgroundColor,
        importing: true,
      ));
      controller.addJavaScriptHandler(
          handlerName: 'onMetadata',
          callback: (args) async {
            Map<String, dynamic> metadata = args[0];
            String title = metadata['title'] ?? 'Unknown';
            dynamic authorData = metadata['author'];
            String author = authorData is String
                ? authorData
                : authorData
                        ?.map((author) =>
                            author is String ? author : author['name'])
                        ?.join(', ') ??
                    'Unknown';

            // base64 cover
            String cover = metadata['cover'] ?? '';
            String description = metadata['description'] ?? '';
            await saveBook(file, title, author, description, cover);
            updateBookList?.call();
          });
    },
    onConsoleMessage: (controller, consoleMessage) {
      if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
        throw Exception('Webview: ${consoleMessage.message}');
      }
      webviewConsoleMessage(controller, consoleMessage);
    },
  );

  await webview.dispose();
  await webview.run();
  headlessInAppWebView = webview;
}
