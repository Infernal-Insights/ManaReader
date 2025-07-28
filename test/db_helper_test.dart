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

  });
}
