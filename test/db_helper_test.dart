import 'package:flutter_test/flutter_test.dart';
import 'package:mana_reader/database/db_helper.dart';
import 'package:mana_reader/models/book_model.dart';

void main() {
  final db = DbHelper.instance;

  test('insert and fetch book', () async {
    final id = await db.insertBook(
      BookModel(title: 'Title', path: '/path', language: 'en'),
    );
    final book = await db.fetchBook(id);
    expect(book?.title, 'Title');
  });

  test('update book metadata', () async {
    final id = await db.insertBook(
      BookModel(title: 'Old', path: '/old', language: 'en'),
    );
    await db.updateBook(id, title: 'New', path: '/new', tags: ['a']);
    final book = await db.fetchBook(id);
    expect(book?.title, 'New');
    expect(book?.path, '/new');
    expect(book?.tags, ['a']);
  });

  test('delete book', () async {
    final id = await db.insertBook(
      BookModel(title: 'Delete', path: '/d', language: 'en'),
    );
    final rows = await db.deleteBook(id);
    expect(rows, 1);
    final book = await db.fetchBook(id);
    expect(book, isNull);
  });

  test('history logging', () async {
    final id = await db.insertBook(
      BookModel(title: 'History', path: '/h', language: 'en'),
    );
    await db.updateProgress(id, 5);
    final history = await db.fetchHistory(id);
    expect(history.length, 1);
    expect(history.first['page'], 5);
  });
}
