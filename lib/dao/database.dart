import 'dart:async';
import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const CREATE_BOOK_SQL = '''
CREATE TABLE tb_books (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  cover_path TEXT,
  file_path TEXT,
  last_read_position TEXT,
  reading_percentage REAL,
  author TEXT,
  is_deleted INTEGER,
  description TEXT,
  create_time TEXT,
  update_time TEXT
)
''';

const CREATE_THEME_SQL = '''
CREATE TABLE tb_themes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  background_color TEXT,
  text_color TEXT,
  background_image_path TEXT
)
''';

const CREATE_STYLE_SQL = '''
CREATE TABLE tb_styles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  font_size REAL,
  font_family TEXT,
  line_height REAL,
  letter_spacing REAL,
  word_spacing REAL,
  paragraph_spacing REAL,
  side_margin REAL,
  top_margin REAL,
  bottom_margin REAL
)
''';

const PRIMARY_THEME_1 = '''
INSERT INTO tb_themes (background_color, text_color, background_image_path) VALUES ('fffbfbf3', 'ff343434', '')
''';
const PRIMARY_THEME_2 = '''
INSERT INTO tb_themes (background_color, text_color, background_image_path) VALUES ('ff040404', 'fffeffeb', '')
''';

const CREATE_NOTE_SQL = '''
CREATE TABLE tb_notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER,
  content TEXT,
  cfi TEXT,
  chapter TEXT,
  type TEXT,
  color TEXT,
  create_time TEXT,
  update_time TEXT
)
''';

const CREATE_READING_TIME_SQL = '''
CREATE TABLE tb_reading_time (
  id INTEGER PRIMARY KEY,
  book_id INTEGER,
  date TEXT,
  reading_time INTEGER
)
''';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() {
    return _instance;
  }

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final databasePath = await getAnxDataBasesPath();
        final path = join(databasePath, 'app_database.db');
        return await openDatabase(
          path,
          version: 4,
          onCreate: (db, version) async {
            onUpgradeDatabase(db, 0, version);
          },
          onUpgrade: onUpgradeDatabase,
        );
      case TargetPlatform.windows:
        sqfliteFfiInit();
        var databaseFactory = databaseFactoryFfi;

        final databasePath = await getAnxDataBasesPath();
        AnxLog.info('Database: database path: $databasePath');
        final path = join(databasePath, 'app_database.db');

        return await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 3,
            onCreate: (db, version) async {
              onUpgradeDatabase(db, 0, version);
            },
            onUpgrade: onUpgradeDatabase,
          ),
        );
      default:
        throw Exception('Unsupported platform');
    }
  }

  static void close() {
    _database?.close();
    _database = null;
  }

  Future<void> onUpgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    AnxLog.info('Database: upgrade database from $oldVersion to $newVersion');
    switch (oldVersion) {
      case 0:
        AnxLog.info('Database: create database version $newVersion');
        await db.execute(CREATE_BOOK_SQL);
        await db.execute(CREATE_NOTE_SQL);
        await db.execute(CREATE_THEME_SQL);
        await db.execute(CREATE_STYLE_SQL);
        await db.execute(CREATE_READING_TIME_SQL);
        await db.execute(PRIMARY_THEME_1);
        await db.execute(PRIMARY_THEME_2);
        continue case1;
      case1:
      case 1:
        // add a column (rating) to tb_books
        await db.execute('ALTER TABLE tb_books ADD COLUMN rating REAL');
        // remove '/data/user/0/com.anxcye.anx_reader/app_flutter/' from file_path & cover_path
        await db.execute(
            'UPDATE tb_books SET file_path = REPLACE(file_path, "/data/user/0/com.anxcye.anx_reader/app_flutter/", "")');
        await db.execute(
            'UPDATE tb_books SET cover_path = REPLACE(cover_path, "/data/user/0/com.anxcye.anx_reader/app_flutter/", "")');
        continue case2;
      case2:
      case 2:
        // replave ' ' with '_' in db and cut file name to 25
        await db.execute(
            'UPDATE tb_books SET file_path = REPLACE(file_path, " ", "_")');
        await db.execute(
            'UPDATE tb_books SET cover_path = REPLACE(cover_path, " ", "_")');
        await db.execute(
            'UPDATE tb_books SET file_path = SUBSTR(file_path, 0, 25)');
        await db.execute(
            'UPDATE tb_books SET cover_path = SUBSTR(cover_path, 0, 25)');
        await db
            .execute('UPDATE tb_books SET file_path = file_path || ".epub"');
        await db
            .execute('UPDATE tb_books SET cover_path = cover_path || ".png"');

        final basePath = getBasePath('');
        final fileDir = Directory('$basePath/file');
        final coverDir = Directory('$basePath/cover');
        fileDir.listSync().forEach((element) {
          if (element is File) {
            final path = element.path;
            String pathAfterReplace = path.replaceAll(' ', '_');
            int endIndex =
                (pathAfterReplace.length < 72) ? pathAfterReplace.length : 72;
            final newPath = '${pathAfterReplace.substring(0, endIndex)}.epub';
            element.rename(newPath);
          }
        });
        coverDir.listSync().forEach((element) {
          if (element is File) {
            final path = element.path;
            String pathAfterReplace = path.replaceAll(' ', '_');
            int endIndex =
                (pathAfterReplace.length < 72) ? pathAfterReplace.length : 72;
            final newPath = '${pathAfterReplace.substring(0, endIndex)}.png';
            element.rename(newPath);
          }
        });
        continue case3;
      case3:
      case 3:
        // remove former book style
        Prefs().removeBookStyle();
        selectBooks().then((books) {
          for (var book in books) {
            if (!File(book.coverFullPath).existsSync()) {
              resetBookCover(book);
            }
          }
        });
    }
  }
}
