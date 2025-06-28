import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/theme.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/page/home_page.dart';
import 'package:anx_reader/page/iap_page.dart';
import 'package:anx_reader/providers/ai_chat.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/service/convert_to_epub/txt/convert_from_txt.dart';
import 'package:anx_reader/service/iap_service.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/import_book.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/webView/gererate_url.dart';
import 'package:anx_reader/utils/webView/webview_console_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_player/book_player_server.dart';

HeadlessInAppWebView? headlessInAppWebView;

/// import book list and **delete file**
void importBookList(List<File> fileList, BuildContext context, WidgetRef ref) {
  final allowBookExtensions = ["epub", "mobi", "azw3", "fb2", "txt", "pdf"];

  AnxLog.info('importBook fileList: ${fileList.toString()}');

  List<File> supportedFiles = fileList.where((file) {
    return allowBookExtensions.contains(file.path.split('.').last);
  }).toList();

  List<File> unsupportedFiles = fileList.where((file) {
    return !allowBookExtensions.contains(file.path.split('.').last);
  }).toList();

  // delete unsupported files
  for (var file in unsupportedFiles) {
    file.deleteSync();
  }

  Widget bookItem(String path, Widget icon) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: icon,
        ),
        Expanded(
          child: Text(
            path.split('/').last,
            style: const TextStyle(
                fontWeight: FontWeight.w300,
                // fontSize: ,
                overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
    );
  }

  showDialog(
      context: context,
      builder: (BuildContext context) {
        String currentHandlingFile = '';
        List<String> errorFiles = [];

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title:
                Text(L10n.of(context).import_n_books_selected(fileList.length)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.of(context)
                      .import_support_types(allowBookExtensions.join(' / '))),
                  const SizedBox(height: 10),
                  if (unsupportedFiles.isNotEmpty)
                    Text(L10n.of(context)
                        .import_n_books_not_support(unsupportedFiles.length)),
                  const SizedBox(height: 20),
                  for (var file in unsupportedFiles)
                    bookItem(file.path, const Icon(Icons.error)),
                  for (var file in supportedFiles)
                    file.path == currentHandlingFile
                        ? bookItem(
                            file.path,
                            Container(
                              padding: const EdgeInsets.all(3),
                              width: 20,
                              height: 20,
                              child: const CircularProgressIndicator(),
                            ))
                        : bookItem(
                            file.path,
                            errorFiles.contains(file.path)
                                ? const Icon(Icons.error)
                                : const Icon(Icons.done)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  for (var file in supportedFiles) {
                    file.deleteSync();
                  }
                },
                child: Text(L10n.of(context).common_cancel),
              ),
              if (supportedFiles.isNotEmpty)
                TextButton(
                    onPressed: () async {
                      for (var file in supportedFiles) {
                        AnxToast.show(file.path.split('/').last);
                        setState(() {
                          currentHandlingFile = file.path;
                        });
                        // try {
                        await importBook(file, ref);
                        // } catch (e) {
                        //   setState(() {
                        //     errorFiles.add(file.path);
                        //   });
                        // }
                      }
                      Navigator.of(navigatorKey.currentContext!).pop('dialog');
                    },
                    child: Text(L10n.of(context)
                        .import_import_n_books(supportedFiles.length))),
            ],
          );
        });
      });
}

Future<void> importBook(File file, WidgetRef ref) async {
  if (file.path.split('.').last == 'txt') {
    final tempFile = await convertFromTxt(file);
    file.deleteSync();
    file = tempFile;
  }

  await getBookMetadata(file, ref: ref);
  ref.read(bookListProvider.notifier).refresh();
}

Future<void> pushToReadingPage(
  WidgetRef ref,
  BuildContext context,
  Book book, {
  String? cfi,
}) async {
  if (book.isDeleted) {
    AnxToast.show(L10n.of(context).book_deleted);
    return;
  }

  if (!File(book.fileFullPath).existsSync()) {
    ref.read(syncProvider.notifier).downloadBook(book);
    return;
  }

  if (EnvVar.isAppStore) {
    if (!IAPService().isFeatureAvailable) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => const IAPPage(),
        ),
      );
      return;
    }
  }
  ref.read(aiChatProvider.notifier).clear();
  final initialThemes = await selectThemes();
  await Navigator.push(
      navigatorKey.currentContext!,
      CupertinoPageRoute(
        builder: (c) => ReadingPage(
          key: readingPageKey,
          book: book,
          cfi: cfi,
          initialThemes: initialThemes,
        ),
      ));
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
      '${title.length > 20 ? title.substring(0, 20) : title}-${DateTime.now().millisecondsSinceEpoch}'
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();

  final extension = file.path.split('.').last;

  final dbFilePath = 'file/$newBookName.$extension';
  final filePath = getBasePath(dbFilePath);
  String? dbCoverPath = 'cover/$newBookName';
  // final coverPath = getBasePath(dbCoverPath);

  await file.copy(filePath);
  // remove cached file
  file.delete();

  dbCoverPath = await saveImageToLocal(cover, dbCoverPath);

  Book book = Book(
      id: provideBook != null ? provideBook.id : -1,
      title: title,
      coverPath: dbCoverPath,
      filePath: dbFilePath,
      lastReadPosition: '',
      readingPercentage: 0,
      author: author,
      isDeleted: false,
      rating: 0.0,
      createTime: DateTime.now(),
      updateTime: DateTime.now());

  book.id = await insertBook(book);
  AnxToast.show(L10n.of(navigatorKey.currentContext!).service_import_success);
  headlessInAppWebView?.dispose();
  headlessInAppWebView = null;
  return;
}

Future<void> getBookMetadata(
  File file, {
  Book? book,
  WidgetRef? ref,
}) async {
  String serverFileName = Server().setTempFile(file);

  String cfi = '';

  String bookUrl = "http://127.0.0.1:${Server().port}/$serverFileName";
  AnxLog.info("import start: book url: $bookUrl");

  HeadlessInAppWebView webview = HeadlessInAppWebView(
    webViewEnvironment: webViewEnvironment,
    initialUrlRequest: URLRequest(
        url: WebUri(generateUrl(
      bookUrl,
      cfi,
      importing: true,
    ))),
    onLoadStop: (controller, url) async {
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
            saveBook(file, title, author, description, cover);
            ref?.read(bookListProvider.notifier).refresh();
            // return;
          });
    },
    onConsoleMessage: (controller, consoleMessage) {
      if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
        headlessInAppWebView?.dispose();
        headlessInAppWebView = null;
        throw Exception('Webview: ${consoleMessage.message}');
      }
      webviewConsoleMessage(controller, consoleMessage);
    },
  );

  await webview.dispose();
  await webview.run();
  headlessInAppWebView = webview;
  // max 30s
  int count = 0;
  while (count < 300) {
    if (headlessInAppWebView == null) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 100));
    count++;
  }
  headlessInAppWebView?.dispose();
  headlessInAppWebView = null;
  throw Exception('Import: Get book metadata timeout');
}
