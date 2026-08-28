import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

class BookResourceHandle {
  BookResourceHandle._({
    required this.token,
    required this.url,
    required this.fileName,
    required this.mime,
    required this.size,
    required void Function() revoke,
  }) : _revoke = revoke;

  final String token;
  final String url;
  final String fileName;
  final String mime;
  final int size;
  final void Function() _revoke;
  bool _revoked = false;

  bool get isRevoked => _revoked;

  void revoke() {
    if (_revoked) return;
    _revoked = true;
    _revoke();
  }
}

class _RegisteredBookResource {
  const _RegisteredBookResource({required this.file, required this.fileName});

  final File file;
  final String fileName;
}

class Server {
  static final Server _singleton = Server._internal();

  factory Server() => _singleton;

  Server._internal();

  HttpServer? _server;
  Future<void>? _startFuture;
  final Map<String, _RegisteredBookResource> _bookResources = {};
  final Random _secureRandom = Random.secure();

  bool get isHealthy => _server != null;

  Future<void> ensureStarted() {
    if (_server != null) return Future.value();
    return _startFuture ??= _start().whenComplete(() => _startFuture = null);
  }

  Future<void> start() => ensureStarted();

  Future<void> _start() async {
    final handler = _handleRequests;
    final preferredPort = Prefs().lastServerPort;

    try {
      _server = await io.serve(handler, '127.0.0.1', preferredPort);
    } catch (error, stackTrace) {
      AnxLog.warning(
        'Server: Failed to bind preferred port, using a random port: $error',
        stackTrace,
      );
      _server = await io.serve(handler, '127.0.0.1', 0);
    }

    Prefs().lastServerPort = _server!.port;
    AnxLog.info('Server: Serving on loopback port ${_server!.port}');
  }

  int get port {
    final server = _server;
    if (server == null) throw StateError('Book player server is not started');
    return server.port;
  }

  String get origin => 'http://127.0.0.1:$port';

  Future<void> stop() async {
    final server = _server;
    if (server == null) return;
    final stoppedPort = server.port;
    await server.close(force: true);
    _server = null;
    _bookResources.clear();
    AnxLog.info('Server: Server stopped (port $stoppedPort)');
  }

  Future<BookResourceHandle> registerBookResource(File file) async {
    await ensureStarted();
    if (!await file.exists()) {
      throw FileSystemException('Book resource does not exist', file.path);
    }
    final canonicalPath = await file.resolveSymbolicLinks();
    final approvedFile = File(canonicalPath);
    final fileName = path.basename(canonicalPath);
    final token = _newToken();
    _bookResources[token] = _RegisteredBookResource(
      file: approvedFile,
      fileName: fileName,
    );
    final mime = _contentTypeForPath(fileName);
    final size = await approvedFile.length();
    final encodedName = Uri.encodeComponent(fileName);
    return BookResourceHandle._(
      token: token,
      url: '$origin/book/$token/$encodedName',
      fileName: fileName,
      mime: mime,
      size: size,
      revoke: () => revokeBookResource(token),
    );
  }

  void revokeBookResource(String token) {
    if (_bookResources.remove(token) != null) {
      AnxLog.info('Server: Revoked book resource token=${_redactToken(token)}');
    }
  }

  String _newToken() {
    while (true) {
      final bytes = List<int>.generate(24, (_) => _secureRandom.nextInt(256));
      final token = base64Url.encode(bytes).replaceAll('=', '');
      if (!_bookResources.containsKey(token)) return token;
    }
  }

  String _redactToken(String token) => token.length <= 6
      ? '***'
      : '${token.substring(0, 3)}...${token.substring(token.length - 3)}';

  Future<String> _loadAsset(String assetPath) =>
      rootBundle.loadString(assetPath);

  Future<shelf.Response> _handleRequests(shelf.Request request) async {
    final uriPath = request.requestedUri.path;
    if (uriPath.startsWith('/book/')) return _handleBookRequest(request);
    if (uriPath.startsWith('/js/')) {
      final content = await _loadAsset('assets/js/${path.basename(uriPath)}');
      return shelf.Response.ok(content,
          headers: {'Content-Type': 'application/javascript'});
    }
    if (uriPath.startsWith('/fonts/')) {
      final file = File(
        '${getFontDir().path}/${path.basename(Uri.decodeComponent(uriPath))}',
      );
      if (!file.existsSync()) return shelf.Response.notFound('Font not found');
      return shelf.Response.ok(file.openRead(), headers: {
        'Content-Type': 'font/opentype',
        'cache-control': 'public, max-age=31536000',
      });
    }
    if (uriPath.startsWith('/foliate-js/')) {
      if (uriPath.endsWith('.epub')) {
        final data = await rootBundle.load(
          'assets/foliate-js/${uriPath.substring(12)}',
        );
        return shelf.Response.ok(data.buffer.asUint8List(), headers: {
          'Content-Type': 'application/epub+zip',
        });
      }
      final content =
          await _loadAsset('assets/foliate-js/${uriPath.substring(12)}');
      return shelf.Response.ok(content, headers: {
        'Content-Type': _assetContentType(uriPath),
        'X-Content-Type-Options': 'nosniff',
      });
    }
    if (uriPath.startsWith('/bgimg/')) return _handleBgimgRequest(request);
    return shelf.Response.notFound('Resource not found');
  }

  Future<shelf.Response> _handleBookRequest(shelf.Request request) async {
    if (request.method != 'GET' && request.method != 'HEAD') {
      return shelf.Response(405, headers: {'Allow': 'GET, HEAD'});
    }
    final segments = request.url.pathSegments;
    if (segments.length != 3 || segments.first != 'book') {
      return shelf.Response.notFound('Book resource not found');
    }
    final token = segments[1];
    final resource = _bookResources[token];
    if (resource == null || segments[2] != resource.fileName) {
      return shelf.Response.notFound('Book resource not found');
    }
    if (!await resource.file.exists()) {
      revokeBookResource(token);
      return shelf.Response.notFound('Book resource not found');
    }

    final length = await resource.file.length();
    final commonHeaders = <String, String>{
      'Content-Type': _contentTypeForPath(resource.fileName),
      'Accept-Ranges': 'bytes',
      'X-Content-Type-Options': 'nosniff',
      ..._corsHeaders(request),
    };
    final rangeHeader = request.headers[HttpHeaders.rangeHeader];
    if (rangeHeader == null) {
      final headers = {...commonHeaders, 'Content-Length': '$length'};
      return shelf.Response(
        200,
        body: request.method == 'HEAD' ? null : resource.file.openRead(),
        headers: headers,
      );
    }

    final range = _parseSingleRange(rangeHeader, length);
    if (range == null) {
      return shelf.Response(416, headers: {
        ...commonHeaders,
        'Content-Range': 'bytes */$length',
        'Content-Length': '0',
      });
    }
    final rangeLength = range.end - range.start + 1;
    final headers = {
      ...commonHeaders,
      'Content-Length': '$rangeLength',
      'Content-Range': 'bytes ${range.start}-${range.end}/$length',
    };
    return shelf.Response(
      206,
      body: request.method == 'HEAD'
          ? null
          : resource.file.openRead(range.start, range.end + 1),
      headers: headers,
    );
  }

  Map<String, String> _corsHeaders(shelf.Request request) {
    final requestOrigin = request.headers['origin'];
    return requestOrigin == origin
        ? {'Access-Control-Allow-Origin': origin, 'Vary': 'Origin'}
        : const {};
  }

  _ByteRange? _parseSingleRange(String value, int length) {
    final match = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(value.trim());
    if (match == null || length <= 0) return null;
    final startText = match.group(1)!;
    final endText = match.group(2)!;
    if (startText.isEmpty && endText.isEmpty) return null;
    if (startText.isEmpty) {
      final suffixLength = int.tryParse(endText);
      if (suffixLength == null || suffixLength <= 0) return null;
      final effectiveLength = min(suffixLength, length);
      return _ByteRange(length - effectiveLength, length - 1);
    }
    final start = int.tryParse(startText);
    if (start == null || start >= length) return null;
    final parsedEnd = endText.isEmpty ? length - 1 : int.tryParse(endText);
    if (parsedEnd == null || parsedEnd < start) return null;
    return _ByteRange(start, min(parsedEnd, length - 1));
  }

  String _contentTypeForPath(String filePath) {
    return switch (path.extension(filePath).toLowerCase()) {
      '.epub' => 'application/epub+zip',
      '.mobi' || '.azw3' => 'application/x-mobipocket-ebook',
      '.fb2' => 'application/x-fictionbook+xml',
      '.pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  String _assetContentType(String assetPath) {
    return switch (path.extension(assetPath).toLowerCase()) {
      '.html' => 'text/html',
      '.css' => 'text/css',
      '.js' => 'application/javascript',
      '.json' => 'application/json',
      _ => 'application/octet-stream',
    };
  }

  Future<shelf.Response> _handleBgimgRequest(shelf.Request request) async {
    final bgimgPath = Uri.decodeComponent(request.url.path.substring(6));
    ByteBuffer? file;
    if (bgimgPath.startsWith('assets/')) {
      file = (await rootBundle.load(bgimgPath.substring(7))).buffer;
    } else if (bgimgPath.startsWith('local/')) {
      final filePath = path.join(getBgimgDir().path, bgimgPath.substring(6));
      file = (await File(filePath).readAsBytes()).buffer;
    } else {
      return shelf.Response.notFound('Bgimg not found');
    }
    return shelf.Response.ok(file.asUint8List(),
        headers: {'Content-Type': 'image/png'});
  }
}

class _ByteRange {
  const _ByteRange(this.start, this.end);

  final int start;
  final int end;
}
