import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/page/home_page.dart';
import 'package:anx_reader/service/ai/tools/input/book_content_search_input.dart';
import 'package:anx_reader/service/ai/tools/repository/books_repository.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/webView/gererate_url.dart';
import 'package:anx_reader/utils/webView/webview_console_message.dart';
import 'package:anx_reader/utils/webView/anx_headless_webview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class BookContentSearchRepository {
  BookContentSearchRepository({
    BooksRepository? booksRepository,
    Duration? searchTimeout,
    Duration? sessionIdleTimeout,
  })  : _booksRepository = booksRepository ?? const BooksRepository(),
        _searchTimeout = searchTimeout ?? const Duration(seconds: 15),
        _sessionIdleTimeout = sessionIdleTimeout ?? const Duration(minutes: 3);

  final BooksRepository _booksRepository;
  final Duration _searchTimeout;
  final Duration _sessionIdleTimeout;

  final Map<int, _HeadlessSearchSession> _sessions = {};

  Future<Map<String, dynamic>> search(BookContentSearchInput input) async {
    final keyword = input.keyword.trim();
    if (keyword.isEmpty) {
      throw ArgumentError('keyword must not be empty');
    }

    final book = await _resolveBook(input.bookId);
    AnxLog.info(
        'BookContentSearchRepository: Starting search for book=${book.id}, keyword="$keyword"');

    final session = await _getOrCreateSession(book);

    try {
      final response = await session
          .runSearch(
            keyword: keyword,
            maxResults: input.resolvedMaxResults(),
            maxSnippets: input.resolvedMaxSnippets(),
            maxCharacters: input.resolvedMaxCharacters(),
            timeout: _searchTimeout,
          )
          .timeout(
            _searchTimeout,
            onTimeout: () => throw TimeoutException(
              'Search timed out after ${_searchTimeout.inSeconds} seconds',
            ),
          );

      return {
        'bookId': book.id,
        'bookTitle': book.title,
        'keyword': keyword,
        'results': response.results.map((result) => result.toMap()).toList(),
        'searchDurationMs': response.duration.inMilliseconds,
        'completed': response.completed,
      };
    } on Object catch (error, stackTrace) {
      AnxLog.severe(
          'BookContentSearchRepository: Search failed for book=${book.id}, keyword="$keyword": $error\n$stackTrace');
      rethrow;
    } finally {
      if (session.isActive) {
        session.scheduleDispose(_sessionIdleTimeout);
      } else {
        _sessions.remove(book.id);
      }
    }
  }

  Future<Book> _resolveBook(int bookId) async {
    if (bookId <= 0) {
      throw ArgumentError('bookId must be greater than zero');
    }

    final books = await _booksRepository.fetchByIds([bookId]);
    final book = books[bookId];
    if (book == null) {
      throw StateError('Book with id=$bookId not found.');
    }
    if (book.isDeleted) {
      throw StateError('Book with id=$bookId has been deleted.');
    }
    return book;
  }

  Future<_HeadlessSearchSession> _getOrCreateSession(Book book) async {
    final existing = _sessions[book.id];
    if (existing != null && existing.isActive) {
      existing.cancelDisposalTimer();
      return existing;
    }

    final session = _HeadlessSearchSession(
      book: book,
      idleCallback: () {
        _sessions.remove(book.id);
      },
    );

    _sessions[book.id] = session;
    await session.ensureInitialized();
    return session;
  }
}

class _HeadlessSearchSession {
  _HeadlessSearchSession({
    required this.book,
    required this.idleCallback,
  });

  final Book book;
  final VoidCallback idleCallback;

  AnxHeadlessWebView? _webView;
  InAppWebViewController? _controller;
  final _AsyncLock _lock = _AsyncLock();
  Completer<void>? _readyCompleter;
  _ActiveSearch? _activeSearch;
  Timer? _disposeTimer;
  BookResourceHandle? _bookResource;

  bool get isActive => _webView != null;

  Future<void> ensureInitialized() async {
    if (Platform.isWindows && webViewEnvironment == null) {
      throw StateError(
        'WebViewEnvironment is not initialized. '
        'WebView2 Runtime may not be installed.',
      );
    }

    final ready = _readyCompleter;
    if (_webView != null &&
        _controller != null &&
        ready != null &&
        ready.isCompleted) {
      return;
    }

    _bookResource ??=
        await Server().registerBookResource(File(book.fileFullPath));
    final url = _buildBookUrl(_bookResource!);

    final loadCompleter = Completer<void>();
    _readyCompleter = Completer<void>();

    final headless = AnxHeadlessWebView(
      webViewEnvironment: webViewEnvironment,
      initialUrlRequest: URLRequest(url: WebUri('about:blank')),
      initialSettings: InAppWebViewSettings(
        supportZoom: false,
        // transparentBackground: true,
        isInspectable: kDebugMode,
      ),
      onWebViewCreated: (controller) async {
        _controller = controller;
        controller.addJavaScriptHandler(
          handlerName: 'onSearch',
          callback: (args) {
            if (args.isEmpty) {
              return null;
            }
            final data = args.first;
            if (data is Map<String, dynamic>) {
              _handleSearchEvent(data);
            } else if (data is Map) {
              _handleSearchEvent(Map<String, dynamic>.from(data));
            }
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'onBookLoadError',
          callback: (args) {
            final ready = _readyCompleter;
            if (ready != null && !ready.isCompleted) {
              ready.completeError(
                StateError(
                  'Reader failed to load: '
                  '${args.isEmpty ? 'unknown error' : args.first}',
                ),
              );
            }
            return null;
          },
        );
        controller.addJavaScriptHandler(
          handlerName: 'onLoadEnd',
          callback: (args) {
            final ready = _readyCompleter;
            if (ready != null && !ready.isCompleted) {
              ready.complete();
            }
            return null;
          },
        );
        await controller.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
      },
      onLoadStop: (controller, url) {
        if (!loadCompleter.isCompleted) {
          loadCompleter.complete();
        }
      },
      onConsoleMessage: webviewConsoleMessage,
      onLoadError: (controller, url, code, message) {
        if (!loadCompleter.isCompleted) {
          loadCompleter.completeError(
            Exception('Failed to load reader: [$code] $message'),
          );
        }
      },
      onLoadHttpError: (controller, url, statusCode, description) {
        if (!loadCompleter.isCompleted) {
          loadCompleter.completeError(
            Exception(
                'HTTP error while loading reader: [$statusCode] $description'),
          );
        }
      },
    );

    _webView = headless;
    await headless.run();
    await loadCompleter.future.timeout(const Duration(seconds: 15),
        onTimeout: () async {
      await headless.dispose();
      _webView = null;
      _controller = null;
      _bookResource?.revoke();
      _bookResource = null;
      throw TimeoutException('Timed out loading reader for book ${book.id}');
    });

    final readyCompleter = _readyCompleter;
    if (readyCompleter != null && !readyCompleter.isCompleted) {
      await readyCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () async {
          await headless.dispose();
          _webView = null;
          _controller = null;
          _bookResource?.revoke();
          _bookResource = null;
          throw TimeoutException(
            'Timed out waiting for reader initialization for book ${book.id}',
          );
        },
      );
    }
  }

  Future<_SearchResponse> runSearch({
    required String keyword,
    required int maxResults,
    required int maxSnippets,
    required int? maxCharacters,
    required Duration timeout,
  }) {
    return _lock.synchronized(() async {
      cancelDisposalTimer();
      await ensureInitialized();
      await _waitUntilReady();
      final controller = _controller;
      if (controller == null) {
        throw StateError('WebView controller is not initialized');
      }

      final trimmedKeyword = keyword.trim();
      if (trimmedKeyword.isEmpty) {
        throw ArgumentError('keyword must not be empty');
      }

      final search = _ActiveSearch(
        maxResults: maxResults,
        maxSnippets: maxSnippets,
        maxCharacters: maxCharacters,
      );
      _activeSearch = search;

      final escapedKeyword = jsonEncode(trimmedKeyword);

      final stopwatch = Stopwatch()..start();
      search.stopwatch = stopwatch;

      try {
        await controller.evaluateJavascript(source: 'clearSearch()');
        await controller.evaluateJavascript(
          source:
              'search($escapedKeyword, {"scope":"book","matchCase":false,"matchDiacritics":false,"matchWholeWords":false})',
        );
      } on Object {
        _activeSearch = null;
        rethrow;
      }

      try {
        final response =
            await search.completer.future.timeout(timeout, onTimeout: () {
          if (!search.completer.isCompleted) {
            search.completer.completeError(TimeoutException(
                'Search handler timeout after ${timeout.inSeconds} seconds'));
          }
          return search.completer.future;
        });
        stopwatch.stop();
        return response.copyWith(duration: stopwatch.elapsed);
      } finally {
        await controller.evaluateJavascript(source: 'clearSearch()');
        _activeSearch = null;
      }
    });
  }

  void scheduleDispose(Duration duration) {
    cancelDisposalTimer();
    _disposeTimer = Timer(duration, () async {
      await dispose();
      idleCallback();
    });
  }

  void cancelDisposalTimer() {
    _disposeTimer?.cancel();
    _disposeTimer = null;
  }

  Future<void> dispose() async {
    cancelDisposalTimer();
    final webView = _webView;
    _webView = null;
    _controller = null;
    _readyCompleter = null;
    _bookResource?.revoke();
    _bookResource = null;
    if (webView != null) {
      try {
        await webView.dispose();
      } catch (error, stackTrace) {
        AnxLog.warning(
            'HeadlessSearchSession(${book.id}): Failed to dispose webview: $error\n$stackTrace');
      }
    }
  }

  void _handleSearchEvent(Map<String, dynamic> data) {
    final active = _activeSearch;
    if (active == null) {
      return;
    }

    if (data.containsKey('process')) {
      final progress = _toDouble(data['process']);
      if (progress >= 1.0 && !active.completer.isCompleted) {
        active.complete(completed: true);
      }
      return;
    }

    if (active.results.length >= active.maxResults) {
      return;
    }

    try {
      final result = _SearchResult.fromJson(
        Map<String, dynamic>.from(data),
        maxSnippets: active.maxSnippets,
        maxCharacters: active.maxCharacters,
      );
      active.results.add(result);
      if (active.results.length >= active.maxResults) {
        active.complete(completed: true);
      }
    } on Object catch (error, stackTrace) {
      if (!active.completer.isCompleted) {
        active.completer.completeError(error, stackTrace);
      }
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  Future<void> _waitUntilReady() async {
    final completer = _readyCompleter;
    if (completer == null) {
      throw StateError('Reader not initialized');
    }
    if (completer.isCompleted) {
      return;
    }
    await completer.future;
  }

  String _buildBookUrl(BookResourceHandle resource) {
    final initialCfi = book.lastReadPosition;
    return generateUrl(
      resource.url,
      initialCfi,
      importing: false,
    );
  }
}

class _ActiveSearch {
  _ActiveSearch({
    required this.maxResults,
    required this.maxSnippets,
    required this.maxCharacters,
  });

  final int maxResults;
  final int maxSnippets;
  final int? maxCharacters;
  final List<_SearchResult> results = [];
  final Completer<_SearchResponse> completer = Completer<_SearchResponse>();
  late Stopwatch stopwatch;

  void complete({required bool completed}) {
    if (completer.isCompleted) {
      return;
    }
    stopwatch.stop();
    completer.complete(_SearchResponse(
      results: List<_SearchResult>.from(results),
      completed: completed,
      duration: stopwatch.elapsed,
    ));
  }
}

class _SearchResult {
  _SearchResult({
    required this.chapterTitle,
    required this.chapterCfi,
    required this.matches,
  });

  final String chapterTitle;
  final String chapterCfi;
  final List<_SearchMatch> matches;

  Map<String, dynamic> toMap() {
    return {
      'chapterTitle': chapterTitle,
      'chapterCfi': chapterCfi,
      'matches': matches.map((match) => match.toMap()).toList(),
    };
  }

  static _SearchResult fromJson(
    Map<String, dynamic> json, {
    required int maxSnippets,
    required int? maxCharacters,
  }) {
    final label = (json['label'] as String?)?.trim() ?? '';
    final cfi = (json['cfi'] as String?)?.trim() ?? '';
    final rawSubitems = (json['subitems'] as List?) ?? const [];

    final matches = <_SearchMatch>[];
    for (final entry in rawSubitems.take(maxSnippets)) {
      if (entry is Map<String, dynamic>) {
        matches.add(_SearchMatch.fromJson(entry, maxCharacters: maxCharacters));
      } else if (entry is Map) {
        matches.add(
          _SearchMatch.fromJson(
            Map<String, dynamic>.from(entry),
            maxCharacters: maxCharacters,
          ),
        );
      }
    }

    return _SearchResult(
      chapterTitle: label,
      chapterCfi: cfi,
      matches: matches,
    );
  }
}

class _SearchMatch {
  _SearchMatch({
    required this.cfi,
    required this.pre,
    required this.match,
    required this.post,
  });

  final String cfi;
  final String pre;
  final String match;
  final String post;

  Map<String, dynamic> toMap() {
    return {
      'cfi': cfi,
      'pre': pre,
      'match': match,
      'post': post,
    };
  }

  static _SearchMatch fromJson(
    Map<String, dynamic> json, {
    required int? maxCharacters,
  }) {
    final cfi = (json['cfi'] as String?)?.trim() ?? '';
    final excerpt = (json['excerpt'] as Map?) ?? const {};
    final pre = _sanitizeSnippet(excerpt['pre'], maxCharacters);
    final match = _sanitizeSnippet(excerpt['match'], maxCharacters);
    final post = _sanitizeSnippet(excerpt['post'], maxCharacters);

    return _SearchMatch(
      cfi: cfi,
      pre: pre,
      match: match,
      post: post,
    );
  }

  static String _sanitizeSnippet(dynamic value, int? maxCharacters) {
    final content = (value is String ? value : value?.toString() ?? '').trim();
    if (maxCharacters == null || content.length <= maxCharacters) {
      return content;
    }
    return content.substring(0, maxCharacters);
  }
}

class _SearchResponse {
  const _SearchResponse({
    required this.results,
    required this.completed,
    required this.duration,
  });

  final List<_SearchResult> results;
  final bool completed;
  final Duration duration;

  _SearchResponse copyWith({
    List<_SearchResult>? results,
    bool? completed,
    Duration? duration,
  }) {
    return _SearchResponse(
      results: results ?? this.results,
      completed: completed ?? this.completed,
      duration: duration ?? this.duration,
    );
  }
}

class _AsyncLock {
  Future<void> _pending = Future.value();

  Future<T> synchronized<T>(Future<T> Function() action) {
    final completer = Completer<void>();
    final previous = _pending;
    _pending = completer.future;
    return previous.then((_) => action()).whenComplete(() {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
  }
}
