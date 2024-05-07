import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<String> convertDbToJson() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'app_database.db');
  final db = await openDatabase(path);

  final tables = ['tb_books', 'tb_notes', 'tb_themes', 'tb_styles', 'tb_reading_time'];

  Map<String, List<Map<String, dynamic>>> databaseMap = {};

  for (final table in tables) {
    final result = await db.query(table);
    databaseMap[table] = result;
  }

  await db.close();

  String json = jsonEncode(databaseMap);

  return json;
}
