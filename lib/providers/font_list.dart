import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/font_model.dart';
import 'package:anx_reader/utils/font_parser.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';

part 'font_list.g.dart';

@Riverpod(keepAlive: true)
class FontList extends _$FontList {
  @override
  Future<List<FontModel>> build() async {
    return await loadFonts();
  }

  Future<List<FontModel>> loadFonts() async {
    Directory fontDir = getFontDir();
    List<FontModel> fontList = [
      FontModel(
        label: L10n.of(navigatorKey.currentContext!).system_font,
        name: 'system',
        path: '',
      ),
    ];

    for (int i = 0; i < fontDir.listSync().length; i++) {
      File element = fontDir.listSync()[i] as File;
      fontList.add(FontModel(
        label: getFontNameFromFile(element),
        name: 'customFont$i',
        path: element.path.split(Platform.pathSeparator).last,
      ));
    }
    for (var font in fontList) {
      if (font.path.isEmpty) {
        continue;
      }
      
      final fontLoader = FontLoader(font.path);
      final fontData = await File(getFontDir().path + Platform.pathSeparator + font.path).readAsBytes();

      fontLoader.addFont(Future.value(fontData.buffer.asByteData()));

      await fontLoader.load();
    }
    return fontList;
  }

  Future<void> refresh() async {
    state = AsyncData(await loadFonts());
  }
}
