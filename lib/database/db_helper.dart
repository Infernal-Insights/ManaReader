import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../models/book_model.dart';
import '../metadata/metadata_service.dart';

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
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDir.path, 'mana_reader.db');
    return openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        // Ensure foreign key constraints are enforced
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE books(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            path TEXT,
            author TEXT,
            language TEXT,
            tags TEXT,
            last_page INTEGER,
            favorite INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER,
            page INTEGER,
            timestamp INTEGER,
            FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE bookmarks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id INTEGER,
            page INTEGER,
            FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE INDEX idx_books_author ON books(author);');
        await db.execute('CREATE INDEX idx_books_language ON books(language);');
        await db.execute('CREATE INDEX idx_books_title ON books(title);');
        await db.execute('CREATE INDEX idx_books_favorite ON books(favorite);');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE bookmarks(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              book_id INTEGER,
              page INTEGER
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE books ADD COLUMN favorite INTEGER DEFAULT 0',
          );
        }
        if (oldVersion < 4) {
          await db.execute('CREATE INDEX idx_books_author ON books(author);');
          await db.execute(
            'CREATE INDEX idx_books_language ON books(language);',
          );
          await db.execute('CREATE INDEX idx_books_title ON books(title);');
          await db.execute(
            'CREATE INDEX idx_books_favorite ON books(favorite);',
          );
        }
      },
    );
  }

  Future<int> insertBook(BookModel book) async {
    final db = await database;
    return db.insert('books', book.toMap());
  }

  Future<BookModel?> fetchBook(int id) async {
    final db = await database;
    final maps = await db.query('books', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return BookModel.fromMap(maps.first);
  }

  Future<int> updateBook(BookModel book) async {
    if (book.id == null) throw ArgumentError('Book id cannot be null');
    final db = await database;
    return db.update(
      'books',
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<void> toggleFavorite(int id, bool isFav) async {
    final db = await database;
    await db.update(
      'books',
      {'favorite': isFav ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBook(int id) async {
    final db = await database;
    String? path;
    try {
      final result = await db.query(
        'books',
        columns: ['path'],
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isNotEmpty) {
        path = result.first['path'] as String?;
      }
    } on DatabaseException catch (e, st) {
      debugPrint('Failed to fetch book path for id $id: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }

    final rows = await db.delete('books', where: 'id = ?', whereArgs: [id]);

    // Clean up related history and bookmarks entries
    await db.delete('history', where: 'book_id = ?', whereArgs: [id]);
    await db.delete('bookmarks', where: 'book_id = ?', whereArgs: [id]);

    if (path != null) {
      final dir = Directory(path);
      try {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } on FileSystemException catch (e, st) {
        debugPrint('Failed to delete directory at $path: $e');
        debugPrintStack(stackTrace: st);
        return -1;
      }
    }

    return rows;
  }

  /// Imports a book from the given path and resolves metadata using [service].
  Future<int> importBook(String path, MetadataService service) async {
    final name = p.basenameWithoutExtension(path);
    final meta = await service.resolve(name);
    if (meta == null) {
      debugPrint('Metadata lookup failed for "$name"');
    }

    final book = BookModel(
      title: meta?.title ?? name,
      path: path,
      language: meta?.language ?? 'unknown',
      tags: meta?.tags ?? const [],
    );
    return insertBook(book);
  }

  Future<List<BookModel>> fetchBooks({
    List<String>? tags,
    String? author,
    String? language,
    bool? unread,
    bool? favorite,
    String? query,
    String? orderBy,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];
    if (tags != null && tags.isNotEmpty) {
      for (final tag in tags) {
        where.add('tags LIKE ?');
        args.add('%$tag%');
      }
    }
    if (author != null && author.isNotEmpty) {
      where.add('author = ?');
      args.add(author);
    }
    if (language != null && language.isNotEmpty) {
      where.add('language = ?');
      args.add(language);
    }
    if (unread != null) {
      where.add(unread ? 'last_page = 0' : 'last_page > 0');
    }
    if (favorite != null) {
      where.add('favorite = ?');
      args.add(favorite ? 1 : 0);
    }
    if (query != null && query.isNotEmpty) {
      where.add('title LIKE ?');
      args.add('%$query%');
    }
    String? orderClause;
    if (orderBy != null) {
      switch (orderBy) {
        case 'title':
          orderClause = 'title COLLATE NOCASE ASC';
          break;
        case 'author':
          orderClause = 'author COLLATE NOCASE ASC';
          break;
        case 'recent':
          orderClause =
              '(SELECT MAX(timestamp) FROM history WHERE book_id = books.id) DESC';
          break;
      }
    }
    final maps = await db.query(
      'books',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: orderClause,
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

  Future<List<String>> fetchAllLanguages() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT language FROM books WHERE language IS NOT NULL AND language != ""',
    );
    return maps.map((e) => e['language'] as String).toList();
  }

  Future<List<String>> fetchAllTags() async {
    final db = await database;
    final maps = await db.query('books', columns: ['tags']);
    final set = <String>{};
    for (final map in maps) {
      final tagStr = map['tags'] as String? ?? '';
      set.addAll(
        tagStr
            .split(',')
            .map((e) => e.trim())
            .where((element) => element.isNotEmpty),
      );
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

  /// Returns books that have history entries ordered by most recent read.
  Future<List<BookModel>> fetchHistoryBooks() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT b.* FROM books b
      JOIN history h ON b.id = h.book_id
      GROUP BY b.id
      ORDER BY MAX(h.timestamp) DESC
    ''');
    return maps.map((e) => BookModel.fromMap(e)).toList();
  }

  Future<void> addBookmark(int bookId, int page) async {
    final db = await database;
    await db.insert('bookmarks', {'book_id': bookId, 'page': page});
  }

  Future<void> removeBookmark(int bookId, int page) async {
    final db = await database;
    await db.delete(
      'bookmarks',
      where: 'book_id = ? AND page = ?',
      whereArgs: [bookId, page],
    );
  }

  Future<List<int>> fetchBookmarks(int bookId) async {
    final db = await database;
    final maps = await db.query(
      'bookmarks',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
    return maps.map((e) => e['page'] as int).toList();
  }

  /// Closes the underlying database and resets the instance.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
