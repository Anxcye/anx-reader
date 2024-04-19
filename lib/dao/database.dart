import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

const CREATE_BOOK_SQL = '''
CREATE TABLE tb_books (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  cover_path TEXT,
  file_path TEXT,
  last_read_position TEXT,
  reading_percentage REAL,
  author TEXT,
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
INSERT INTO tb_themes (background_color, text_color, background_image_path) VALUES ('ff121212', 'ffcccccc', '')
''';
const PRIMARY_THEME_2 = '''
INSERT INTO tb_themes (background_color, text_color, background_image_path) VALUES ('ffcccccc', 'ff121212', '')
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
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'app_database.db');

    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute(CREATE_BOOK_SQL);
      await db.execute(CREATE_NOTE_SQL);
      await db.execute(CREATE_THEME_SQL);
      await db.execute(CREATE_STYLE_SQL);
      await db.execute(CREATE_READING_TIME_SQL);
      await db.execute(PRIMARY_THEME_1);
      await db.execute(PRIMARY_THEME_2);
    });
  }
}
