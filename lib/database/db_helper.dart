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
            author TEXT,
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


  Future<List<BookModel>> fetchBooks({
    List<String>? tags,
    String? author,
    bool? unread,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        where.add('tags LIKE ?');
        args.add('%' + tag + '%');
      }
    }
    if (author != null && author.isNotEmpty) {
      where.add('author = ?');
      args.add(author);
    }
    if (unread != null) {
      where.add(unread ? 'last_page = 0' : 'last_page > 0');
    }
    final maps = await db.query(
      'books',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
    );
    return maps.map((e) => BookModel.fromMap(e)).toList();
  }

  Future<List<String>> fetchAllAuthors() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT author FROM books WHERE author IS NOT NULL AND author != ""',
    );
    return maps.map((e) => e['author'] as String).toList();
  }

  Future<List<String>> fetchAllTags() async {
    final db = await database;
    final maps = await db.query('books', columns: ['tags']);
    final set = <String>{};
    for (final map in maps) {
      final tagStr = map['tags'] as String? ?? '';
      set.addAll(tagStr
          .split(',')
          .map((e) => e.trim())
          .where((element) => element.isNotEmpty));
    }
    return set.toList();

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
