import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mana_reader/models/book_model.dart';
import 'package:mana_reader/screens/reader_screen.dart';

void main() {
  testWidgets('displays book title', (tester) async {
    final book = BookModel(title: 'Read Me', path: '/tmp', language: 'en');
    await tester.pumpWidget(MaterialApp(home: ReaderScreen(book: book)));
    expect(find.text('Reader for Read Me'), findsOneWidget);
  });
}
