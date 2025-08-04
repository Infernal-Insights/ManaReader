import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mana_reader/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:mana_reader/models/book_model.dart';
import 'package:mana_reader/screens/library_screen.dart';
import 'package:mana_reader/database/db_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LibraryScreen(
        fetchBooks: ({tags, author, language, unread, favorite, query, orderBy}) async => [],
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('No books imported'), findsOneWidget);
  });

  testWidgets('displays inserted books', (tester) async {
    final books = [BookModel(title: 'A', path: '/tmp/a.cbz', language: 'en')];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LibraryScreen(
        fetchBooks: ({tags, author, language, unread, favorite, query, orderBy}) async => books,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('toggles list and grid view', (tester) async {
    final books = [BookModel(title: 'B', path: '/tmp/b.cbz', language: 'en')];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LibraryScreen(
          fetchBooks: ({tags, author, language, unread, favorite, query, orderBy}) async => books),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
    final btn = find.byIcon(Icons.view_list);
    await tester.tap(btn);
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('shows delete dialog on long press', (tester) async {
    final books = [
      BookModel(id: 1, title: 'X', path: '/tmp/x.cbz', language: 'en')
    ];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LibraryScreen(
          fetchBooks: ({tags, author, language, unread, favorite, query, orderBy}) async => books),
    ));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('X'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Book'), findsOneWidget);
  });

  testWidgets('opens detail screen from menu', (tester) async {
    final books = [
      BookModel(id: 1, title: 'E', path: '/tmp/e.cbz', language: 'en')
    ];
    await tester.pumpWidget(MaterialApp(
      home: LibraryScreen(
          fetchBooks: ({tags, author, language, unread, favorite, query, orderBy}) async => books),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.text('Book Details'), findsOneWidget);
  });

  testWidgets('filters by language', (tester) async {
    final fakeDb = DbHelper();
    // Initialize ffi for db usage
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = _FakePathProviderPlatform();
    await fakeDb.insertBook(BookModel(title: 'EN', path: '/tmp/en.cbz', language: 'en'));
    await fakeDb.insertBook(BookModel(title: 'JP', path: '/tmp/jp.cbz', language: 'jp'));

    final books = [
      BookModel(title: 'EN', path: '/tmp/en.cbz', language: 'en'),
      BookModel(title: 'JP', path: '/tmp/jp.cbz', language: 'jp'),
    ];

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LibraryScreen(
        fetchBooks: ({tags, author, language, unread, favorite, query, orderBy}) async {
          return books.where((b) => language == null || b.language == language).toList();
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('EN'), findsOneWidget);
    expect(find.text('JP'), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('jp').last);
    await tester.pumpAndSettle();

    expect(find.text('EN'), findsNothing);
    expect(find.text('JP'), findsOneWidget);
  });

  testWidgets('favorite filter button', (tester) async {
    bool? receivedFavorite;
    final books = [BookModel(title: 'F', path: '/tmp/f.cbz', language: 'en')];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LibraryScreen(fetchBooks: ({tags, author, language, unread, favorite, query, orderBy}) async {
        receivedFavorite = favorite;
        return books;
      }),
    ));
    await tester.pumpAndSettle();

    expect(receivedFavorite, isNull);
    await tester.tap(find.byIcon(Icons.star_border));
    await tester.pumpAndSettle();
    expect(receivedFavorite, isTrue);
  });

  testWidgets('filters by multiple tags', (tester) async {
    final fakeDb = DbHelper();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    PathProviderPlatform.instance = _FakePathProviderPlatform();
    await fakeDb.insertBook(BookModel(
        title: 'A', path: '/tmp/a.cbz', language: 'en', tags: ['a']));
    await fakeDb.insertBook(BookModel(
        title: 'B', path: '/tmp/b.cbz', language: 'en', tags: ['b']));
    await fakeDb.insertBook(BookModel(
        title: 'AB', path: '/tmp/ab.cbz', language: 'en', tags: ['a', 'b']));

    final books = [
      BookModel(title: 'A', path: '/tmp/a.cbz', language: 'en', tags: ['a']),
      BookModel(title: 'B', path: '/tmp/b.cbz', language: 'en', tags: ['b']),
      BookModel(title: 'AB', path: '/tmp/ab.cbz', language: 'en', tags: ['a', 'b']),
    ];

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LibraryScreen(
        fetchBooks: ({tags, author, language, unread, favorite, query, orderBy}) async {
          return books.where((b) {
            if (tags != null && tags.isNotEmpty) {
              for (final t in tags) {
                if (!b.tags.contains(t)) return false;
              }
            }
            return true;
          }).toList();
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('AB'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'a'));
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('AB'), findsOneWidget);
    expect(find.text('B'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'b'));
    await tester.pumpAndSettle();
    expect(find.text('AB'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsNothing);

    await tester.tap(find.widgetWithText(FilterChip, 'Clear').first);
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('AB'), findsOneWidget);
  });
}
