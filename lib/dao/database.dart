import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

const CREATE_BOOK_SQL = '''
CREATE TABLE tb_books (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT,
  cover_path TEXT,
  file_path TEXT,
  last_read_position TEXT,
  author TEXT,
  description TEXT
)
''';

const CREATE_NOTE_SQL = '''
CREATE TABLE tb_notes (
  id INTEGER PRIMARY KEY,
  book_id INTEGER,
  content TEXT,
  position TEXT
  
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
    });
  }
}
