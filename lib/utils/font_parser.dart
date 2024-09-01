import 'dart:io';
import 'dart:typed_data';

import 'package:anx_reader/config/shared_preference_provider.dart';

Map<String, int> fontCache = {
  'en': 1033,
  'zh': 2052,
};

String getFontNameFromFile(File file) {
  Uint8List fontData = file.readAsBytesSync();

  int? nameTableOffset = _getNameTableOffset(fontData);

  if (nameTableOffset == null) {
    return 'Invalid font file';
  }

  int count = _readUint16(fontData, nameTableOffset + 2);
  int stringOffset = _readUint16(fontData, nameTableOffset + 4);
  String languageCode = Prefs().locale?.languageCode ?? Platform.localeName.split('_').first;
  int specifiedLanguageId = fontCache[languageCode] ?? fontCache['en']!;

  for (int i = 0; i < count; i++) {
    int recordOffset = nameTableOffset + 6 + i * 12;

    int platformID = _readUint16(fontData, recordOffset);
    int languageID = _readUint16(fontData, recordOffset + 4);
    int nameID = _readUint16(fontData, recordOffset + 6);

    if (nameID == 1 && platformID == 3 && languageID == specifiedLanguageId) {
      int length = _readUint16(fontData, recordOffset + 8);
      int offset = _readUint16(fontData, recordOffset + 10);

      return _readUnicodeString(
          fontData, nameTableOffset + stringOffset + offset, length);
    }
  }

  return file.path.split('/').last.split('.').first;
}

String _readUnicodeString(Uint8List data, int offset, int length) {
  List<int> codeUnits = [];
  for (int i = 0; i < length; i += 2) {
    codeUnits.add((data[offset + i] << 8) | data[offset + i + 1]);
  }
  return String.fromCharCodes(codeUnits);
}

int? _getNameTableOffset(Uint8List fontData) {
  int numTables = _readUint16(fontData, 4);

  for (int i = 0; i < numTables; i++) {
    int offset = 12 + i * 16;
    String tag = String.fromCharCodes(fontData.sublist(offset, offset + 4));

    if (tag == 'name') {
      return _readUint32(fontData, offset + 8);
    }
  }

  return null;
}

int _readUint16(Uint8List data, int offset) {
  return (data[offset] << 8) | data[offset + 1];
}

int _readUint32(Uint8List data, int offset) {
  return (data[offset] << 24) |
      (data[offset + 1] << 16) |
      (data[offset + 2] << 8) |
      data[offset + 3];
}
