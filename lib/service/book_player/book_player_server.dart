import 'dart:io';
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
    var handler = const shelf.Pipeline().addMiddleware(shelf.logRequests()).addHandler(_handleRequests);

    _server = await io.serve(handler, 'localhost', 0);
    print('Serving at http://${_server?.address.host}:${_server?.port}');
  }

  int get port  {
    return _server!.port;
  }

  Future stop() async {
    await _server?.close(force: true);
    print('Server stopped');
  }

 Future<String> loadAsset(String path) async {
  return await rootBundle.loadString(path);
}
Future<shelf.Response> _handleRequests(shelf.Request request) async {
  final uriPath = request.requestedUri.path;

  if (uriPath.startsWith('/book/')) {
    return _handleBookRequest(request);
  }
  else if (uriPath.startsWith('/js/')) {
    String content = await loadAsset('assets/js/${path.basename(uriPath)}');
    return shelf.Response.ok(
      content,
      headers: {'Content-Type': 'application/javascript'},
    );
  }
  else {
    return shelf.Response.ok(
      'Request for "${request.url}"',
      headers: {'Access-Control-Allow-Origin': '*'},
    );
  }
}

  shelf.Response _handleBookRequest(shelf.Request request) {
    final bookPath = Uri.decodeComponent(request.url.path.substring(5));
    final file = File(bookPath);
    print('Request for book: $bookPath');
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