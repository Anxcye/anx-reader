import 'dart:io';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

class Server {
  static final Server _singleton = Server._internal();

  factory Server() {
    return _singleton;
  }

  Server._internal();

  HttpServer? _server;

  Future start() async {
    var handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(_handleRequests);

    _server = await io.serve(handler, 'localhost', 0);
    AnxLog.info(
        'Server: Serving at http://${_server?.address.host}:${_server?.port}');
  }

  int get port {
    return _server!.port;
  }

  Future stop() async {
    await _server?.close(force: true);
    AnxLog.info('Server: Server stopped');
  }

  Future<String> _loadAsset(String path) async {
    return await rootBundle.loadString(path);
  }

  File? _tempFile;
  String? _tempFileName;

  String setTempFile(File file) {
    _tempFile = file;
    _tempFileName = DateTime.timestamp().hashCode.toString();
    return _tempFileName!;
  }

  Future<shelf.Response> _handleRequests(shelf.Request request) async {
    final uriPath = request.requestedUri.path;
    AnxLog.info('Server: Request for $uriPath');

    if (_tempFileName != null && uriPath == "/${_tempFileName!}") {
      return shelf.Response.ok(
        _tempFile?.openRead(),
        headers: {
          'Content-Type': 'application/epub+zip',
          'Access-Control-Allow-Origin': '*',
        },
      );
    }

    if (uriPath.startsWith('/book/')) {
      return _handleBookRequest(request);
    } else if (uriPath.startsWith('/js/')) {
      String content = await _loadAsset('assets/js/${path.basename(uriPath)}');
      return shelf.Response.ok(
        content,
        headers: {'Content-Type': 'application/javascript'},
      );
    } else if (uriPath.startsWith('/fonts/')) {
      Directory fontDir = getFontDir();
      final file = File('${fontDir.path}/${path.basename(Uri.decodeComponent(uriPath))}');
      if (!file.existsSync()) {
        return shelf.Response.notFound('Font not found');
      }
      return shelf.Response.ok(
        file.openRead(),
        headers: {
          'Content-Type': 'font/opentype',
          'Access-Control-Allow-Origin': '*',
          'cache-control': 'public, max-age=31536000',
        },
      );
    } else if (uriPath.startsWith('/foliate-js/')) {
      if (uriPath.endsWith('.epub')) {
        final file =
            await rootBundle.load('assets/foliate-js/${uriPath.substring(12)}');
        return shelf.Response.ok(
          file.buffer.asUint8List(),
          headers: {
            'Content-Type': 'application/epub+zip',
            'Access-Control-Allow-Origin': '*', // Add this line
          },
        );
      }
      String content =
          await _loadAsset('assets/foliate-js/${uriPath.substring(12)}');
      String contentType =
          uriPath.endsWith('.html') ? 'text/html' : 'application/javascript';
      return shelf.Response.ok(
        content,
        headers: {
          'Content-Type': contentType,
        },
      );
    } else {
      return shelf.Response.ok(
        'Request for "${request.url}"',
        headers: {
          'Access-Control-Allow-Origin': '*',
        },
      );
    }
  }

  shelf.Response _handleBookRequest(shelf.Request request) {
    final bookPath = Uri.decodeComponent(request.url.path.substring(5));
    final file = File(bookPath);
    AnxLog.info('Server: Request for book: $bookPath');
    if (!file.existsSync()) {
      return shelf.Response.notFound('Book not found');
    }
    final headers = {
      'Content-Type': 'application/epub+zip',
      'Access-Control-Allow-Origin': '*',
    };
    return shelf.Response.ok(file.openRead(), headers: headers);
  }
}
