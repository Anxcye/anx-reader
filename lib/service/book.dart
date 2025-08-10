import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/theme.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/enums/sync_trigger.dart';
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
import 'package:anx_reader/service/md5_service.dart';
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
final allowBookExtensions = ["epub", "mobi", "azw3", "fb2", "txt", "pdf"];

/// import book list and **delete file**
void importBookList(List<File> fileList, BuildContext context, WidgetRef ref) {
  AnxLog.info('importBook fileList: ${fileList.toString()}');

  List<File> supportedFiles = fileList.where((file) {
    return allowBookExtensions
        .contains(file.path.split('.').last.toLowerCase());
  }).toList();

  List<File> unsupportedFiles = fileList.where((file) {
    return !allowBookExtensions
        .contains(file.path.split('.').last.toLowerCase());
  }).toList();

  _checkDuplicatesAndShowDialog(
    supportedFiles,
    unsupportedFiles,
    fileList,
    context,
    ref,
  );
}

void _checkDuplicatesAndShowDialog(
    List<File> supportedFiles,
    List<File> unsupportedFiles,
    List<File> fileList,
    BuildContext context,
    WidgetRef ref) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(L10n.of(context).md5Calculating),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(L10n.of(context).md5Calculating),
        ],
      ),
    ),
  );

  try {
    final filePaths = supportedFiles.map((f) => f.path).toList();
    final checkResults = await MD5Service.checkImportFiles(filePaths);

    Navigator.of(context).pop();

    List<File> duplicateFiles = [];
    List<File> uniqueFiles = [];
    Map<String, Book> duplicateInfo = {};

    for (int i = 0; i < supportedFiles.length; i++) {
      final file = supportedFiles[i];
      final result = checkResults[i];

      if (result.isDuplicate && result.duplicateBook != null) {
        duplicateFiles.add(file);
        duplicateInfo[file.path] = result.duplicateBook!;
      } else {
        uniqueFiles.add(file);
      }
    }

    _showImportDialog(
      uniqueFiles,
      duplicateFiles,
      duplicateInfo,
      unsupportedFiles,
      fileList,
      ref,
    );
  } catch (e) {
    Navigator.of(navigatorKey.currentContext!).pop();
    AnxLog.severe('MD5 check failed: $e');
    _showImportDialog(
      supportedFiles,
      [],
      {},
      unsupportedFiles,
      fileList,
      ref,
    );
  }
}

void _showImportDialog(
  List<File> uniqueFiles,
  List<File> duplicateFiles,
  Map<String, Book> duplicateInfo,
  List<File> unsupportedFiles,
  List<File> fileList,
  WidgetRef ref,
) {
  // delete unsupported files
  for (var file in unsupportedFiles) {
    file.deleteSync();
  }

  BuildContext context = navigatorKey.currentContext!;

  Widget bookItem(String path, Widget icon,
      {bool isDuplicate = false, String? duplicateTitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: icon,
            ),
            Expanded(
              child: Text(
                path.split('/').last,
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        if (isDuplicate && duplicateTitle != null)
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 2),
            child: Text(
              L10n.of(context).duplicateOf(duplicateTitle),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  final supportedFiles = [...uniqueFiles, ...duplicateFiles];
  bool skipDuplicates = true;

  showDialog(
      context: context,
      builder: (BuildContext context) {
        String currentHandlingFile = '';
        List<String> errorFiles = [];
        bool finished = false;

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title:
                Text(L10n.of(context).importNBooksSelected(fileList.length)),
            contentPadding: const EdgeInsets.all(16),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.of(context)
                      .importSupportTypes(allowBookExtensions.join(' / '))),

                  const SizedBox(height: 10),

                  // show unique files
                  for (var file in uniqueFiles)
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

                  // show unsupported files
                  if (unsupportedFiles.isNotEmpty) ...[
                    Divider(),
                    SizedBox(height: 10),
                    Text(L10n.of(context)
                        .importNBooksNotSupport(unsupportedFiles.length))
                  ],
                  for (var file in unsupportedFiles)
                    bookItem(file.path, const Icon(Icons.error)),

                  // show duplicate files
                  if (duplicateFiles.isNotEmpty) ...[
                    Divider(),
                    const SizedBox(height: 10),
                    Text(L10n.of(context).duplicateFile),
                  ],
                  for (var file in duplicateFiles)
                    if (skipDuplicates)
                      bookItem(
                        file.path,
                        const Icon(Icons.double_arrow_rounded),
                        isDuplicate: true,
                        duplicateTitle: duplicateInfo[file.path]?.title,
                      )
                    else
                      file.path == currentHandlingFile
                          ? bookItem(
                              file.path,
                              Container(
                                padding: const EdgeInsets.all(3),
                                width: 20,
                                height: 20,
                                child: const CircularProgressIndicator(),
                              ),
                              isDuplicate: true,
                              duplicateTitle: duplicateInfo[file.path]?.title,
                            )
                          : bookItem(
                              file.path,
                              errorFiles.contains(file.path)
                                  ? const Icon(Icons.error)
                                  : const Icon(Icons.done),
                              isDuplicate: true,
                              duplicateTitle: duplicateInfo[file.path]?.title,
                            ),

                  // select skip duplicates
                  if (duplicateFiles.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: skipDuplicates,
                          onChanged: (value) {
                            setState(() {
                              skipDuplicates = value ?? true;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(L10n.of(context).skipDuplicateFiles),
                        ),
                      ],
                    ),
                  ],
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
                child: Text(L10n.of(context).commonCancel),
              ),
              if (uniqueFiles.isNotEmpty ||
                  (duplicateFiles.isNotEmpty && !skipDuplicates))
                TextButton(
                    onPressed: () async {
                      if (finished) {
                        Navigator.of(context).pop('dialog');
                        return;
                      }

                      List<File> filesToImport = [...uniqueFiles];
                      if (!skipDuplicates) {
                        filesToImport.addAll(duplicateFiles);
                      }

                      for (var file in filesToImport) {
                        AnxToast.show(file.path.split('/').last);
                        setState(() {
                          currentHandlingFile = file.path;
                        });
                        try {
                          await importBook(file, ref);
                          setState(() {
                            currentHandlingFile = '';
                          });
                        } catch (e) {
                          setState(() {
                            errorFiles.add(file.path);
                          });
                        }
                      }

                      // dumplicateFiles will be deleted if skipDuplicates is true
                      // if skipDuplicates is false, they will be imported
                      // and then deleted in the importBook function
                      if (skipDuplicates) {
                        for (var file in duplicateFiles) {
                          file.deleteSync();
                        }
                      }

                      setState(() {
                        finished = true;
                      });
                      ref.read(syncProvider.notifier).syncData(
                          SyncDirection.upload, ref,
                          trigger: SyncTrigger.auto);
                    },
                    child: Text(finished
                        ? L10n.of(context).commonOk
                        : L10n.of(context).importImportNBooks(
                            uniqueFiles.length +
                                (skipDuplicates ? 0 : duplicateFiles.length) -
                                errorFiles.length))),
            ],
          );
        });
      });
}

Future<void> importBook(File file, WidgetRef ref) async {
  String? md5 = await MD5Service.calculateFileMd5(file.path);

  if (file.path.split('.').last == 'txt') {
    final tempFile = await convertFromTxt(file);
    file.deleteSync();
    file = tempFile;
  }

  await getBookMetadata(file, md5: md5, ref: ref);
  ref.read(bookListProvider.notifier).refresh();
}

Future<void> pushToReadingPage(
  WidgetRef ref,
  BuildContext context,
  Book book, {
  String? cfi,
}) async {
  if (book.isDeleted) {
    AnxToast.show(L10n.of(context).bookDeleted);
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
  String? md5,
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
  if (md5 != null) {
    provideBook ??= await getBookByMd5(md5);
  }

  Book book = Book(
      id: provideBook != null ? provideBook.id : -1,
      title: provideBook?.title ?? title,
      coverPath: dbCoverPath,
      filePath: dbFilePath,
      lastReadPosition: provideBook?.lastReadPosition ?? '',
      readingPercentage: provideBook?.readingPercentage ?? 0,
      author: provideBook?.author ?? author,
      isDeleted: false,
      rating: provideBook?.rating ?? 0.0,
      md5: md5,
      createTime: provideBook?.createTime ?? DateTime.now(),
      updateTime: DateTime.now());

  book.id = await insertBook(book);
  AnxToast.show(L10n.of(navigatorKey.currentContext!).serviceImportSuccess);
  headlessInAppWebView?.dispose();
  headlessInAppWebView = null;
  return;
}

Future<void> getBookMetadata(
  File file, {
  Book? book,
  String? md5,
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
            saveBook(
              file,
              title,
              author,
              description,
              md5,
              cover,
              provideBook: book,
            );
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
