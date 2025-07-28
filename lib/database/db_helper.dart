import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/book_model.dart';

/// Handles initialization and CRUD operations for the local SQLite database.
class DbHelper {
  static final DbHelper instance = DbHelper._internal();

  factory DbHelper() => instance;

  DbHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, 'mana_reader.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE books(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            path TEXT,
            language TEXT,
            tags TEXT,
            last_page INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER,
            page INTEGER,
            timestamp INTEGER
          )
        ''');
      },
    );
  }

  Future<int> insertBook(BookModel book) async {
    final db = await database;
    return db.insert('books', book.toMap());
  }

  Future<BookModel?> fetchBook(int id) async {
    final db = await database;
    final maps = await db.query(
      'books',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BookModel.fromMap(maps.first);
  }

  Future<List<BookModel>> fetchBooks() async {
    final db = await database;
    final maps = await db.query('books');
    return maps.map((e) => BookModel.fromMap(e)).toList();
  }

  Future<int> updateBook(int id,
      {String? title, String? path, List<String>? tags}) async {
    final db = await database;
    final values = <String, Object?>{};
    if (title != null) values['title'] = title;
    if (path != null) values['path'] = path;
    if (tags != null) values['tags'] = tags.join(',');
    if (values.isEmpty) return 0;
    return db.update(
      'books',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBook(int id) async {
    final db = await database;
    await db.delete('history', where: 'book_id = ?', whereArgs: [id]);
    return db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateProgress(int id, int page) async {
    final db = await database;
    await db.update(
      'books',
      {'last_page': page},
      where: 'id = ?',
      whereArgs: [id],
    );
    await insertHistory(id, page);
  }

  Future<int> insertHistory(int bookId, int page) async {
    final db = await database;
    return db.insert('history', {
      'book_id': bookId,
      'page': page,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> fetchHistory(int bookId) async {
    final db = await database;
    return db.query('history', where: 'book_id = ?', whereArgs: [bookId]);
  }
}
