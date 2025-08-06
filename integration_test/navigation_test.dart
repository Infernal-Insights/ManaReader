import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mana_reader/database/db_helper.dart';
import 'package:mana_reader/main.dart';
import 'package:mana_reader/models/book_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('User journey', () {
    late BookModel book;

    setUpAll(() async {
      final dir = await Directory.systemTemp.createTemp('mana_reader_test');
      final imageFile = File('${dir.path}/page1.png');
      // 1x1 transparent png
      const base64Png =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMB/ax5oQAAAABJRU5ErkJggg==';
      await imageFile.writeAsBytes(base64Decode(base64Png));

      book = BookModel(
        title: 'Test Book',
        path: dir.path,
        language: 'en',
        pages: [imageFile.path],
      );
      await DbHelper.instance.insertBook(book);
    });

    testWidgets('open book through library', (tester) async {
      await tester.pumpWidget(const ManaReaderApp());
      await tester.pumpAndSettle();

      // Navigate to library
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(find.text('Test Book'), findsOneWidget);

      // Open the book
      await tester.tap(find.text('Test Book'));
      await tester.pumpAndSettle();
      expect(find.text('Test Book'), findsWidgets);

      // Navigate back to library and main menu
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Test Book'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Library'), findsOneWidget);
    });
  });
}

