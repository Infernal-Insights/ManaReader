import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:mana_reader/models/book_model.dart';
import 'package:mana_reader/screens/library_screen.dart';

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
  setUp(() {
    // No-op setup for path provider to avoid method channel errors.
    PathProviderPlatform.instance = _FakePathProviderPlatform();
  });

  testWidgets('shows empty message with no books', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LibraryScreen(fetchBooks: () async => []),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('No books imported'), findsOneWidget);
  });

  testWidgets('displays inserted books', (tester) async {
    final books = [BookModel(title: 'A', path: '/tmp/a.cbz', language: 'en')];
    await tester.pumpWidget(MaterialApp(
      home: LibraryScreen(fetchBooks: () async => books),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('A'), findsOneWidget);
  });
}
