import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/utils/toast/common.dart';

import 'database.dart';

Future<int> insertTheme(ReadTheme readTheme) async {
  final db = await DBHelper().database;
  return db.insert('tb_themes', readTheme.toMap());
}

Future<List<ReadTheme>> selectThemes() async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.query('tb_themes');
  return List.generate(maps.length, (i) {
    return ReadTheme(
      id: maps[i]['id'],
      backgroundColor: maps[i]['background_color'],
      textColor: maps[i]['text_color'],
      backgroundImagePath: maps[i]['background_image_path'],
    );
  });
}

void deleteTheme(int id) async {
  final db = await DBHelper().database;
  final numberOfCurrentThemes = await db.query('tb_themes');
  if (numberOfCurrentThemes.length <= 2) {
    AnxToast.show(L10n.of(navigatorKey.currentContext!).reading_page_at_least_two_themes);
    return;
  }
  await db.delete(
    'tb_themes',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<void> updateTheme(ReadTheme readTheme) async {
  final db = await DBHelper().database;
  await db.update(
    'tb_themes',
    readTheme.toMap(),
    where: 'id = ?',
    whereArgs: [readTheme.id],
  );
}

Future<ReadTheme> selectReadThemeById(int id) {
  final db = DBHelper().database;
  return db.then((value) async {
    final List<Map<String, dynamic>> maps = await value.query(
      'tb_themes',
      where: 'id = ?',
      whereArgs: [id],
    );
    return ReadTheme(
      id: maps[0]['id'],
      backgroundColor: maps[0]['background_color'],
      textColor: maps[0]['text_color'],
      backgroundImagePath: maps[0]['background_image_path'],
    );
  });
}
