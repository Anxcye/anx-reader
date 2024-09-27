import 'dart:convert';
import 'dart:typed_data';

Uint8List convertStringToUint8List(String source) {
  // utf8 encode
  List<int> list = utf8.encode(source);
  return Uint8List.fromList(list);
}
