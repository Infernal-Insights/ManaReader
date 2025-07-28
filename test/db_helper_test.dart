import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mana_reader/database/db_helper.dart';
import 'package:mana_reader/models/book_model.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final Directory tempDir =
      Directory.systemTemp.createTempSync('mana_reader_test');

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempDir.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  PathProviderPlatform.instance = _FakePathProviderPlatform();

  group('DbHelper', () {
    late DbHelper dbHelper;

    setUp(() {
      PathProviderPlatform.instance = _FakePathProviderPlatform();
      dbHelper = DbHelper();
    });

    test('insert and fetch book', () async {
      final book =
          BookModel(title: 'Test', path: '/tmp/test.cbz', language: 'en');
      final id = await dbHelper.insertBook(book);
      expect(id, isNonZero);

      final books = await dbHelper.fetchBooks();
      expect(books, hasLength(1));
      expect(books.first.title, equals('Test'));
    });

    test('update progress', () async {
      final book =
          BookModel(title: 'Test', path: '/tmp/test.cbz', language: 'en');
      final id = await dbHelper.insertBook(book);
      await dbHelper.updateProgress(id, 5);
      final books = await dbHelper.fetchBooks();
      final updated = books.singleWhere((b) => b.id == id);
      expect(updated.lastPage, equals(5));
    });

    test('fetch by id', () async {
      final book =
          BookModel(title: 'ById', path: '/tmp/test.cbz', language: 'en');
      final id = await dbHelper.insertBook(book);
      final fetched = await dbHelper.fetchBook(id);
      expect(fetched, isNotNull);
      expect(fetched!.id, equals(id));
      expect(fetched.title, equals('ById'));
    });

    test('update book metadata', () async {
      final id = await dbHelper.insertBook(
          BookModel(title: 'Old', path: '/tmp/test.cbz', language: 'en'));
      final updated = BookModel(
        id: id,
        title: 'New',
        path: '/tmp/test.cbz',
        language: 'jp',
        author: 'Me',
        tags: ['tag'],
      );
      await dbHelper.updateBook(updated);
      final fetched = await dbHelper.fetchBook(id);
      expect(fetched!.title, equals('New'));
      expect(fetched.language, equals('jp'));
      expect(fetched.author, equals('Me'));
      expect(fetched.tags, equals(['tag']));
    });

    test('delete book', () async {
      final id = await dbHelper
          .insertBook(BookModel(title: 'Del', path: '/tmp/a.cbz', language: 'en'));
      await dbHelper.deleteBook(id);
      final books = await dbHelper.fetchBooks();
      expect(books, isEmpty);
    });

  });
}
