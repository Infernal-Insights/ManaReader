import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:mana_reader/models/book_model.dart';
import 'package:mana_reader/screens/reader_screen.dart';

void main() {
  testWidgets('displays book title and page view', (tester) async {
    // create a temporary 1x1 png
    final dir = Directory.systemTemp.createTempSync();
    final imgPath = p.join(dir.path, 'a.png');
    final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=');
    File(imgPath).writeAsBytesSync(bytes);

    final book = BookModel(
      title: 'Read Me',
      path: dir.path,
      language: 'en',
      pages: [imgPath],
    );
    await tester.pumpWidget(MaterialApp(home: ReaderScreen(book: book)));
    expect(find.text('Read Me'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
  });
}
