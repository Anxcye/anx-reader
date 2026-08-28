import 'dart:async';
import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/theme.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/enums/sync_trigger.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/current_reading_state.dart';
import 'package:anx_reader/page/home_page.dart';
import 'package:anx_reader/page/iap_page.dart';
import 'package:anx_reader/providers/ai_chat.dart';
import 'package:anx_reader/providers/chapter_content_bridge.dart';
import 'package:anx_reader/providers/current_reading.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:anx_reader/providers/iap.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/providers/toc_search.dart';
import 'package:anx_reader/service/convert_to_epub/txt/convert_from_txt.dart';
import 'package:anx_reader/service/convert_to_epub/markdown/convert_from_markdown.dart';
import 'package:anx_reader/service/md5_service.dart';
import 'package:anx_reader/utils/webView/anx_headless_webview.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/import_book.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/platform_utils.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/webView/gererate_url.dart';
import 'package:anx_reader/utils/webView/webview_console_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import 'book_player/book_player_server.dart';
import 'book_player/book_open_policy.dart';
import 'book_player/reader_runtime.dart';

AnxHeadlessWebView? headlessInAppWebView;
final allowBookExtensions = [
  "epub",
  "mobi",
  "azw3",
  "fb2",
  "txt",
  "md",
  "markdown",
  "pdf",
];

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

  Widget bookItem(
    String filePath,
    Widget icon, {
    bool isDuplicate = false,
    String? duplicateTitle,
    String? errorMessage,
  }) {
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
                path.basename(filePath),
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (errorMessage != null)
              IconButton(
                icon: const Icon(Icons.info_outline, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(L10n.of(context).commonError),
                      content: SelectableText(errorMessage),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(L10n.of(context).commonOk),
                        ),
                      ],
                    ),
                  );
                },
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
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 2),
            child: Text(
              'Error: ${errorMessage.length > 50 ? "${errorMessage.substring(0, 50)}..." : errorMessage}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
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
        Map<String, String> errorMessages = {};

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text(L10n.of(context).importNBooksSelected(fileList.length)),
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
                                : const Icon(Icons.done),
                            errorMessage: errorFiles.contains(file.path)
                                ? errorMessages[file.path]
                                : null,
                          ),

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
                              errorMessage: errorFiles.contains(file.path)
                                  ? errorMessages[file.path]
                                  : null,
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
                        AnxToast.show(path.basename(file.path));
                        setState(() {
                          currentHandlingFile = file.path;
                        });
                        try {
                          await importBook(file, ref);
                          setState(() {
                            currentHandlingFile = '';
                          });
                        } catch (e, stackTrace) {
                          AnxLog.severe('Failed to import ${file.path}: $e');
                          AnxLog.severe('Stack trace: $stackTrace');
                          setState(() {
                            errorFiles.add(file.path);
                            errorMessages[file.path] = e.toString();
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
  final importId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final originalName = path.basename(file.path);
  final stopwatch = Stopwatch()..start();
  try {
    final size = await file.length();
    AnxLog.info(
      'BookImport[$importId] stage=import_start file=$originalName size=$size',
    );
    AnxLog.info('BookImport[$importId] stage=md5_start file=$originalName');
    String? md5 = await MD5Service.calculateFileMd5(file.path);
    AnxLog.info(
      'BookImport[$importId] stage=md5_complete available=${md5 != null}',
    );

    final extension = path.extension(file.path).toLowerCase();
    if (extension == '.txt' || extension == '.md' || extension == '.markdown') {
      final format = extension == '.txt' ? 'txt' : 'markdown';
      AnxLog.info('BookImport[$importId] stage=${format}_conversion_start');
      final tempFile = extension == '.txt'
          ? await convertFromTxt(file)
          : await convertFromMarkdown(file);
      file.deleteSync();
      file = tempFile;
      AnxLog.info('BookImport[$importId] stage=${format}_conversion_complete');
    }

    await getBookMetadata(file, md5: md5, importId: importId);
    AnxLog.info('BookImport[$importId] stage=bookshelf_refresh_start');
    await ref.read(bookListProvider.notifier).refresh();
    AnxLog.info(
      'BookImport[$importId] stage=import_complete '
      'durationMs=${stopwatch.elapsedMilliseconds}',
    );
  } catch (error, stackTrace) {
    AnxLog.severe(
      'BookImport[$importId] stage=import_failed file=$originalName '
      'durationMs=${stopwatch.elapsedMilliseconds}',
      error,
      stackTrace,
    );
    rethrow;
  }
}

Future<void> pushToReadingPage(
  WidgetRef ref,
  BuildContext context,
  Book book, {
  String? cfi,
  String? heroTag,
  bool initialShowCoach = false,
}) async {
  if (book.isDeleted) {
    AnxToast.show(L10n.of(context).bookDeleted);
    return;
  }

  final bookFile = File(book.fileFullPath);
  if (!bookFile.existsSync()) {
    ref.read(syncProvider.notifier).downloadBook(book);
    return;
  }

  final extension = path.extension(bookFile.path).replaceFirst('.', '');
  final fileSize = await bookFile.length();
  final isMobile =
      AnxPlatform.isAndroid || AnxPlatform.isIOS || AnxPlatform.isOhos;
  if (BookOpenPolicy.shouldWarn(
    extension: extension,
    fileSize: fileSize,
    isMobile: isMobile,
  )) {
    if (!context.mounted) return;
    final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(L10n.of(dialogContext).bookLargeFileTitle),
            content: Text(
              L10n.of(dialogContext).bookLargeFileMessage(
                BookOpenPolicy.formatMiB(fileSize),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(L10n.of(dialogContext).commonCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(L10n.of(dialogContext).bookLargeFileContinue),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldContinue || !context.mounted) return;
  }

  try {
    await ReaderRuntime.ensureReady();
  } catch (error, stackTrace) {
    AnxLog.severe('Reader runtime initialization failed', error, stackTrace);
    if (!context.mounted) return;
    AnxToast.show('阅读器初始化失败：$error');
    return;
  }

  if (!context.mounted) return;

  if (EnvVar.enableInAppPurchase) {
    final iapAsync = ref.read(iapProvider);
    final isFeatureAvailable = iapAsync.maybeWhen(
      data: (state) => state.isFeatureAvailable,
      orElse: () => ref.read(iapProvider.notifier).cachedFeatureAvailable(),
    );

    if (!isFeatureAvailable) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) => const IAPPage(),
        ),
      );
      return;
    }
  }
  ref.read(aiChatProvider.notifier).clear();
  final initialThemes = await themeDao.selectThemes();
  ref.read(currentReadingProvider.notifier).start(
        CurrentReadingState(
          book: book,
          cfi: cfi,
        ),
      );

  final currentReading = ref.read(currentReadingProvider.notifier);
  final chapterContentBridge = ref.read(chapterContentBridgeProvider.notifier);
  final tocSearch = ref.read(tocSearchProvider.notifier);

  await Navigator.push(
    navigatorKey.currentContext!,
    CupertinoPageRoute(
      builder: (c) => ReadingPage(
        key: readingPageKey,
        book: book,
        cfi: cfi,
        initialThemes: initialThemes,
        heroTag: heroTag,
        initialShowCoach: initialShowCoach,
      ),
    ),
  ).then((_) {
    AnxLog.info('ReadingPage: poped: ${book.title}');
    currentReading.finish();
    chapterContentBridge.state = null;
    tocSearch.clear();
    AnxLog.info('Pop successfully ReadingPage: ${book.title}');
  });
}

void updateBookRating(Book book, double rating) {
  book.rating = rating;
  bookDao.updateBook(book);
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
  String? importId,
}) async {
  final logPrefix = 'BookImport[${importId ?? 'metadata'}]';
  // Extract original filename (without extension)
  final fileNameWithoutExt = path.basenameWithoutExtension(file.path);

  // Use original filename if title is invalid
  final effectiveTitle =
      (title == 'Unknown' || title.trim().isEmpty) ? fileNameWithoutExt : title;

  final newBookName =
      '${effectiveTitle.length > 20 ? effectiveTitle.substring(0, 20) : effectiveTitle}-${DateTime.now().millisecondsSinceEpoch}'
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();

  final extension = file.path.split('.').last;

  final dbFilePath = 'file/$newBookName.$extension';
  final filePath = getBasePath(dbFilePath);
  String? dbCoverPath = 'cover/$newBookName';
  // final coverPath = getBasePath(dbCoverPath);

  AnxLog.info(
      '$logPrefix stage=file_copy_start file=${path.basename(filePath)}');
  final copiedFile = await file.copy(filePath);
  AnxLog.info(
    '$logPrefix stage=file_copy_complete size=${await copiedFile.length()}',
  );
  // remove cached file
  file.delete();

  dbCoverPath = await saveImageToLocal(cover, dbCoverPath);
  if (md5 != null) {
    provideBook ??= await bookDao.getBookByMd5(md5);
  }

  Book book = Book(
      id: provideBook != null ? provideBook.id : -1,
      title: provideBook?.title ?? effectiveTitle,
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

  AnxLog.info('$logPrefix stage=database_write_start');
  book.id = await bookDao.insertBook(book);
  AnxLog.info('$logPrefix stage=database_write_complete bookId=${book.id}');
  AnxToast.show(L10n.of(navigatorKey.currentContext!).serviceImportSuccess);
}

Future<void> getBookMetadata(
  File file, {
  Book? book,
  String? md5,
  String? importId,
}) async {
  final metadataCompleter = Completer<void>();
  bool metadataHandled = false;
  final resource = await Server().registerBookResource(file);

  String cfi = '';

  final bookUrl = resource.url;
  final logPrefix = 'BookImport[${importId ?? 'metadata'}]';
  AnxLog.info('$logPrefix stage=metadata_webview_start');

  AnxHeadlessWebView webview = AnxHeadlessWebView(
    webViewEnvironment: webViewEnvironment,
    initialUrlRequest: URLRequest(url: WebUri('about:blank')),
    onWebViewCreated: (controller) async {
      controller.addJavaScriptHandler(
          handlerName: 'onMetadata',
          callback: (args) async {
            if (metadataHandled) return;
            metadataHandled = true;
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

            String cover = metadata['cover'] ?? '';
            String description = metadata['description'] ?? '';
            AnxLog.info(
              '$logPrefix stage=metadata_received titleLength=${title.length} '
              'hasCover=${cover.isNotEmpty}',
            );
            try {
              await saveBook(
                file,
                title,
                author,
                description,
                md5,
                cover,
                provideBook: book,
                importId: importId,
              );
              metadataCompleter.complete();
            } catch (error, stackTrace) {
              metadataCompleter.completeError(error, stackTrace);
            }
          });
      controller.addJavaScriptHandler(
        handlerName: 'onBookLoadError',
        callback: (args) {
          if (!metadataCompleter.isCompleted) {
            metadataCompleter.completeError(
              Exception(
                  'Webview: ${args.isEmpty ? 'unknown error' : args.first}'),
            );
          }
          return null;
        },
      );
      await controller.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(generateUrl(
            bookUrl,
            cfi,
            importing: true,
          )),
        ),
      );
    },
    onConsoleMessage: (controller, consoleMessage) {
      if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
        if (!metadataCompleter.isCompleted) {
          metadataCompleter.completeError(
            Exception('Webview: ${consoleMessage.message}'),
          );
        }
        return;
      }
      webviewConsoleMessage(controller, consoleMessage);
    },
  );

  headlessInAppWebView = webview;
  try {
    await webview.run();
    AnxLog.info('$logPrefix stage=metadata_webview_running');
    await metadataCompleter.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException(
        'Import: Get book metadata timeout',
        const Duration(seconds: 30),
      ),
    );
  } finally {
    await webview.dispose();
    resource.revoke();
    AnxLog.info('$logPrefix stage=metadata_webview_disposed');
    if (identical(headlessInAppWebView, webview)) {
      headlessInAppWebView = null;
    }
  }
}
