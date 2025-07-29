import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mana_reader/database/db_helper.dart';
import 'package:mana_reader/models/book_model.dart';
import 'package:mana_reader/metadata/metadata_service.dart';
import 'package:mana_reader/metadata/metadata_provider.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final Directory tempDir =
      Directory.systemTemp.createTempSync('mana_reader_test');

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempDir.path;
  }
}

class _FakeMetadataService extends MetadataService {
  @override
  Future<Metadata?> resolve(String query) async {
    return Metadata(title: 'Resolved', language: 'jp', tags: ['tag']);
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

    test('fetchBooks with filters', () async {
      await dbHelper.insertBook(BookModel(
          title: 'A', path: '/tmp/a.cbz', language: 'en', author: 'Alice', tags: ['x']));
      await dbHelper.insertBook(BookModel(
          title: 'B', path: '/tmp/b.cbz', language: 'en', author: 'Bob', tags: ['y'], lastPage: 2));

      final tagFiltered = await dbHelper.fetchBooks(tags: ['x']);
      expect(tagFiltered.map((b) => b.title), ['A']);

      final authorFiltered = await dbHelper.fetchBooks(author: 'Bob');
      expect(authorFiltered.map((b) => b.title), ['B']);

      final unread = await dbHelper.fetchBooks(unread: true);
      expect(unread.map((b) => b.title), ['A']);
    });

    test('fetchAllAuthors and fetchAllTags', () async {
      await dbHelper.insertBook(BookModel(
          title: 'A', path: '/tmp/a.cbz', language: 'en', author: 'Me', tags: ['x','y']));
      await dbHelper.insertBook(BookModel(
          title: 'B', path: '/tmp/b.cbz', language: 'en', author: 'You', tags: ['y']));

      final authors = await dbHelper.fetchAllAuthors();
      expect(authors.toSet(), {'Me', 'You'});

      final tags = await dbHelper.fetchAllTags();
      expect(tags.toSet(), {'x', 'y'});
    });

    test('importBook uses metadata', () async {
      final service = _FakeMetadataService();
      final id = await dbHelper.importBook('/tmp/book.cbz', service);
      final book = await dbHelper.fetchBook(id);
      expect(book, isNotNull);
      expect(book!.title, equals('Resolved'));
      expect(book.language, equals('jp'));
      expect(book.tags, ['tag']);
    });

    test('history insertion and fetch', () async {
      final id = await dbHelper
          .insertBook(BookModel(title: 'Hist', path: '/tmp/h.cbz', language: 'en'));
      await dbHelper.updateProgress(id, 3);
      final history = await dbHelper.fetchHistory(id);
      expect(history, isNotEmpty);
      expect(history.first['page'], 3);
    });

    test('bookmark add and remove', () async {
      final id = await dbHelper
          .insertBook(BookModel(title: 'Bm', path: '/tmp/h.cbz', language: 'en'));
      await dbHelper.addBookmark(id, 2);
      var bookmarks = await dbHelper.fetchBookmarks(id);
      expect(bookmarks, contains(2));
      await dbHelper.removeBookmark(id, 2);
      bookmarks = await dbHelper.fetchBookmarks(id);
      expect(bookmarks, isEmpty);
    });

  });
}
