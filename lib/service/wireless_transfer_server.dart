import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart' as book_dao;
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/service/md5_service.dart';
import 'package:anx_reader/service/convert_to_epub/markdown/convert_from_markdown.dart';
import 'package:anx_reader/service/convert_to_epub/txt/convert_from_txt.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter/services.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

class WirelessTransferServer {
  static final WirelessTransferServer _singleton =
      WirelessTransferServer._internal();

  factory WirelessTransferServer() {
    return _singleton;
  }

  WirelessTransferServer._internal();

  HttpServer? _server;
  Timer? _inactivityTimer;
  final List<Map<String, dynamic>> _uploadHistory = [];

  static const List<String> _supportedExtensions = [
    'epub',
    'pdf',
    'txt',
    'md',
    'markdown',
    'mobi',
    'azw3',
    'fb2',
  ];
  static const int _maxFileSize = 500 * 1024 * 1024; // 500MB
  static const int _maxUploadHistory = 50;

  bool get isRunning => _server != null;

  int get port => _server?.port ?? 0;

  List<Map<String, dynamic>> get uploadHistory =>
      List.unmodifiable(_uploadHistory);

  Future<bool> start({int? portOverride}) async {
    if (_server != null) {
      AnxLog.info('WirelessTransfer: Already running on port ${_server!.port}');
      return true;
    }

    final handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(_handleRequests);

    int port = portOverride ?? Prefs().wirelessTransferPort;

    try {
      _server = await io.serve(handler, InternetAddress.anyIPv4, port);
    } catch (e) {
      AnxLog.warning('WirelessTransfer: Port $port in use, trying random: $e');
      try {
        _server = await io.serve(handler, InternetAddress.anyIPv4, 0);
      } catch (e2) {
        AnxLog.severe('WirelessTransfer: Failed to start server: $e2');
        return false;
      }
    }

    Prefs().wirelessTransferPort = _server!.port;
    AnxLog.info(
        'WirelessTransfer: Server running at http://0.0.0.0:${_server!.port}');

    _resetInactivityTimer();
    return true;
  }

  Future<void> stop() async {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;

    if (_server == null) return;

    final stoppedPort = _server!.port;
    await _server?.close(force: true);
    _server = null;
    AnxLog.info('WirelessTransfer: Server stopped (port $stoppedPort)');
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();

    int shutdownSeconds = Prefs().wirelessTransferAutoShutdown;
    if (shutdownSeconds <= 0) {
      AnxLog.info('WirelessTransfer: Auto-shutdown disabled');
      return;
    }

    _inactivityTimer = Timer(Duration(seconds: shutdownSeconds), () {
      AnxLog.info('WirelessTransfer: Auto-shutdown triggered (idle timeout)');
      stop();
    });

    AnxLog.info(
        'WirelessTransfer: Inactivity timer set for ${shutdownSeconds}s');
  }

  Future<shelf.Response> _handleRequests(shelf.Request request) async {
    _resetInactivityTimer();

    final uriPath = request.requestedUri.path;
    final method = request.method;

    AnxLog.info('WirelessTransfer: $method $uriPath');

    if (method == 'OPTIONS') {
      return shelf.Response.ok('', headers: _corsHeaders);
    }

    if (method == 'GET' && uriPath == '/') {
      return _serveUploadPage();
    }

    if (method == 'POST' && uriPath == '/upload-file') {
      return _handleRawUpload(request);
    }

    if (method == 'POST' && uriPath == '/upload') {
      return _handleUpload(request);
    }

    if (method == 'GET' && uriPath == '/status') {
      return _serveStatus();
    }

    return shelf.Response.ok(
      'Wireless Transfer Server',
      headers: {'Content-Type': 'text/plain'},
    );
  }

  Future<shelf.Response> _serveUploadPage() async {
    try {
      String content =
          await rootBundle.loadString('assets/transfer/index.html');
      return shelf.Response.ok(
        content,
        headers: {
          ..._noCacheHeaders,
          'Content-Type': 'text/html; charset=utf-8',
        },
      );
    } catch (e) {
      return shelf.Response.internalServerError(
        body: 'Upload page not found: $e',
      );
    }
  }

  shelf.Response _serveStatus() {
    final status = {
      'running': isRunning,
      'port': port,
      'uploads': _uploadHistory,
      'supportedExtensions': _supportedExtensions,
      'maxFileSize': _maxFileSize,
    };
    return shelf.Response.ok(
      jsonEncode(status),
      headers: _jsonHeaders,
    );
  }

  Future<shelf.Response> _handleRawUpload(shelf.Request request) async {
    final rawFileName = request.headers['x-file-name'];
    final fileName =
        _sanitizeFileName(_decodeHeaderValue(rawFileName) ?? 'book');
    final contentLength = request.contentLength;

    if (contentLength == null || contentLength <= 0) {
      return _jsonError('Missing file content', statusCode: 400);
    }

    final validationError = _validateUpload(fileName, contentLength);
    if (validationError != null) {
      return _jsonResponse({
        'results': [
          {
            'filename': fileName,
            'success': false,
            'error': validationError,
          }
        ],
      }, statusCode: 400);
    }

    File? tempFile;
    IOSink? sink;
    var bytesWritten = 0;

    try {
      final tempDir = await getAnxTempDir();
      tempFile = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );
      sink = tempFile.openWrite();

      await for (final chunk in request.read()) {
        bytesWritten += chunk.length;
        if (bytesWritten > _maxFileSize) {
          throw const _UploadTooLargeException();
        }
        sink.add(chunk);
      }

      await sink.close();
      sink = null;

      final md5 = await MD5Service.calculateFileMd5(tempFile.path);
      final bookName = _titleFromFileName(fileName);
      await _saveBookToFile(tempFile, bookName, md5);

      _recordUpload(fileName, true, size: bytesWritten);
      return _jsonResponse({
        'results': [
          {
            'filename': fileName,
            'success': true,
            'size': bytesWritten,
          }
        ],
      });
    } on _UploadTooLargeException {
      await sink?.close();
      await _deleteQuietly(tempFile);
      _recordUpload(fileName, false,
          size: bytesWritten,
          error: 'File too large (max ${_maxFileSize ~/ (1024 * 1024)}MB)');
      return _jsonResponse({
        'results': [
          {
            'filename': fileName,
            'success': false,
            'error': 'File too large (max ${_maxFileSize ~/ (1024 * 1024)}MB)',
          }
        ],
      }, statusCode: 413);
    } catch (e, stack) {
      await sink?.close();
      await _deleteQuietly(tempFile);
      AnxLog.severe(
          'WirelessTransfer: Raw upload failed for $fileName: $e\n$stack');
      _recordUpload(fileName, false, size: bytesWritten, error: e.toString());
      return _jsonError(e.toString(), statusCode: 500);
    }
  }

  Future<shelf.Response> _handleUpload(shelf.Request request) async {
    try {
      final contentType = request.headers['content-type'] ?? '';
      final contentLength = request.contentLength;

      if (contentLength != null && contentLength > _maxFileSize + 1024 * 1024) {
        return _jsonError(
          'File too large (max ${_maxFileSize ~/ (1024 * 1024)}MB)',
          statusCode: 413,
        );
      }

      if (!contentType.contains('multipart/form-data')) {
        return _jsonError('Content-Type must be multipart/form-data');
      }

      final boundary = _extractBoundary(contentType);
      if (boundary == null) {
        return _jsonError('Missing boundary in Content-Type');
      }

      final bodyBytes = await request.read().fold<List<int>>(
        <int>[],
        (previous, element) => previous..addAll(element),
      );

      final files = _parseMultipartBytes(bodyBytes, boundary);

      if (files.isEmpty) {
        return shelf.Response.badRequest(
          body: jsonEncode({'error': 'No files found in upload'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final results = <Map<String, dynamic>>[];

      for (final fileData in files) {
        final fileName = _sanitizeFileName(fileData['filename'] as String);
        final contentBytes = fileData['content'] as List<int>;

        final validationError = _validateUpload(fileName, contentBytes.length);
        if (validationError != null) {
          results.add({
            'filename': fileName,
            'success': false,
            'error': validationError,
          });
          continue;
        }

        try {
          final tempDir = await getAnxTempDir();
          final safeName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
          final tempFile = File('${tempDir.path}/$safeName');
          await tempFile.writeAsBytes(contentBytes, flush: true);

          final md5 = await MD5Service.calculateFileMd5(tempFile.path);
          final bookName = _titleFromFileName(fileName);
          await _saveBookToFile(tempFile, bookName, md5);

          results.add({
            'filename': fileName,
            'success': true,
          });

          _recordUpload(fileName, true, size: contentBytes.length);
        } catch (e) {
          AnxLog.severe('WirelessTransfer: Import failed for $fileName: $e');
          results.add({
            'filename': fileName,
            'success': false,
            'error': e.toString(),
          });
          _recordUpload(fileName, false,
              size: contentBytes.length, error: e.toString());
        }
      }

      return _jsonResponse({'results': results});
    } catch (e, stack) {
      AnxLog.severe('WirelessTransfer: Upload error: $e\n$stack');
      return _jsonError(e.toString(), statusCode: 500);
    }
  }

  Map<String, String> get _corsHeaders => const {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers':
            'Content-Type, X-File-Name, X-File-Size',
      };

  Map<String, String> get _jsonHeaders => {
        ..._corsHeaders,
        'Content-Type': 'application/json; charset=utf-8',
      };

  Map<String, String> get _noCacheHeaders => const {
        'Cache-Control': 'no-store, no-cache, must-revalidate',
        'Pragma': 'no-cache',
      };

  shelf.Response _jsonResponse(
    Map<String, dynamic> body, {
    int statusCode = 200,
  }) {
    return shelf.Response(
      statusCode,
      body: jsonEncode(body),
      headers: _jsonHeaders,
    );
  }

  shelf.Response _jsonError(String message, {int statusCode = 400}) {
    return _jsonResponse({'error': message}, statusCode: statusCode);
  }

  String? _validateUpload(String fileName, int size) {
    final ext = fileName.split('.').last.toLowerCase();
    if (fileName == 'book' || !fileName.contains('.')) {
      return 'Missing file name or extension';
    }
    if (!_supportedExtensions.contains(ext)) {
      return 'Unsupported file type. Supported: ${_supportedExtensions.join(', ')}';
    }
    if (size > _maxFileSize) {
      return 'File too large (max ${_maxFileSize ~/ (1024 * 1024)}MB)';
    }
    return null;
  }

  void _recordUpload(
    String fileName,
    bool success, {
    int? size,
    String? error,
  }) {
    _uploadHistory.insert(0, {
      'filename': fileName,
      'time': DateTime.now().toIso8601String(),
      'success': success,
      if (size != null) 'size': size,
      if (error != null) 'error': error,
    });

    if (_uploadHistory.length > _maxUploadHistory) {
      _uploadHistory.removeRange(_maxUploadHistory, _uploadHistory.length);
    }
  }

  String? _decodeHeaderValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return value;
    }
  }

  String _sanitizeFileName(String fileName) {
    final name = fileName
        .split(RegExp(r'[/\\]'))
        .last
        .replaceAll(RegExp(r'[\x00-\x1F<>:"/\\|?*]'), '_')
        .trim();
    return name.isEmpty ? 'book' : name;
  }

  String _titleFromFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
  }

  Future<void> _deleteQuietly(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best-effort temp cleanup.
    }
  }

  String? _extractBoundary(String contentType) {
    final boundaryMatch = RegExp(r'boundary=(.+)').firstMatch(contentType);
    return boundaryMatch?.group(1)?.replaceAll(RegExp(r'^"|"$'), '');
  }

  List<Map<String, dynamic>> _parseMultipartBytes(
      List<int> body, String boundary) {
    final files = <Map<String, dynamic>>[];
    final delimiter = utf8.encode('--$boundary');

    // Find all parts
    int startIdx = 0;
    while (startIdx < body.length) {
      // Find delimiter
      int delimIdx = _findSubsequence(body, delimiter, startIdx);
      if (delimIdx == -1) break;

      // Find end of delimiter line
      int lineEnd = _findLineEnd(body, delimIdx + delimiter.length);

      // Find header/body separator (\r\n\r\n)
      int headerEnd = _findSubsequence(body, [13, 10, 13, 10], lineEnd);
      if (headerEnd == -1) {
        startIdx = lineEnd;
        continue;
      }

      final headerBytes = body.sublist(lineEnd, headerEnd);
      final headerStr = utf8.decode(headerBytes);

      // Check for filename in Content-Disposition header
      final filenameMatch = RegExp(r'filename="([^"]+)"').firstMatch(headerStr);
      if (filenameMatch == null) {
        startIdx = headerEnd + 4;
        continue;
      }

      final filename = filenameMatch.group(1)!;

      // Find end of part (next delimiter or closing --)
      final closingDelimiter = utf8.encode('--$boundary--');
      int nextDelim = _findSubsequence(body, delimiter, headerEnd + 4);
      int nextClosing = _findSubsequence(body, closingDelimiter, headerEnd + 4);

      int endIdx;
      if (nextDelim != -1 && (nextClosing == -1 || nextDelim < nextClosing)) {
        endIdx = nextDelim;
      } else if (nextClosing != -1) {
        endIdx = nextClosing;
      } else {
        break;
      }

      // Extract content, trim trailing \r\n
      var contentEnd = endIdx;
      while (contentEnd > headerEnd + 4 &&
          (body[contentEnd - 1] == 13 || body[contentEnd - 1] == 10)) {
        contentEnd--;
      }

      final contentBytes = body.sublist(headerEnd + 4, contentEnd);

      files.add({
        'filename': filename,
        'content': contentBytes,
      });

      startIdx = endIdx;
    }

    return files;
  }

  int _findSubsequence(List<int> haystack, List<int> needle, int start) {
    if (needle.isEmpty) return -1;
    for (int i = start; i <= haystack.length - needle.length; i++) {
      bool found = true;
      for (int j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }

  int _findLineEnd(List<int> body, int start) {
    for (int i = start; i < body.length; i++) {
      if (body[i] == 13 || body[i] == 10) {
        // Skip all line endings
        while (i < body.length && (body[i] == 13 || body[i] == 10)) {
          i++;
        }
        return i;
      }
    }
    return body.length;
  }

  Future<void> _saveBookToFile(File tempFile, String title, String? md5) async {
    final sourceExtension = tempFile.path.split('.').last.toLowerCase();
    File fileToSave = tempFile;
    if (sourceExtension == 'txt') {
      fileToSave = await convertFromTxt(tempFile);
    } else if (sourceExtension == 'md' || sourceExtension == 'markdown') {
      fileToSave = await convertFromMarkdown(tempFile);
    }
    final extension = fileToSave.path.split('.').last;
    final safeTitle = title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll('\n', '')
        .replaceAll('\r', '')
        .trim();
    final normalizedTitle = safeTitle.isEmpty ? 'book' : safeTitle;
    final bookName =
        '${normalizedTitle.length > 20 ? normalizedTitle.substring(0, 20) : normalizedTitle}-${DateTime.now().millisecondsSinceEpoch}';
    final dbFilePath = 'file/$bookName.$extension';
    final filePath = getBasePath(dbFilePath);

    await fileToSave.copy(filePath);
    if (fileToSave.path != tempFile.path) {
      await fileToSave.delete();
    }
    await tempFile.delete();

    final existingBook =
        md5 != null ? await book_dao.bookDao.getBookByMd5(md5) : null;

    final book = Book(
      id: existingBook?.id ?? -1,
      title: existingBook?.title ?? title,
      coverPath: 'cover/$bookName',
      filePath: dbFilePath,
      lastReadPosition: '',
      readingPercentage: 0,
      author: existingBook?.author ?? '',
      isDeleted: false,
      rating: existingBook?.rating ?? 0.0,
      md5: md5,
      createTime: existingBook?.createTime ?? DateTime.now(),
      updateTime: DateTime.now(),
    );

    await book_dao.bookDao.insertBook(book);
  }
}

class _UploadTooLargeException implements Exception {
  const _UploadTooLargeException();
}
