import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReaderScreen(book: book),
    ));
    expect(find.text('Read Me'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('toggles reading direction', (tester) async {
    final dir = Directory.systemTemp.createTempSync();
    final imgPath = p.join(dir.path, 'a.png');
    File(imgPath).writeAsBytesSync(base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII='));
    final book = BookModel(title: 'Read', path: dir.path, language: 'en', pages: [imgPath]);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReaderScreen(book: book),
    ));
    final btn = find.byIcon(Icons.format_textdirection_l_to_r);
    expect(btn, findsOneWidget);
    await tester.tap(btn);
    await tester.pump();
    expect(find.byIcon(Icons.format_textdirection_r_to_l), findsOneWidget);
  });

  testWidgets('toggles double page mode', (tester) async {
    final dir = Directory.systemTemp.createTempSync();
    final imgPath = p.join(dir.path, 'a.png');
    final img2 = p.join(dir.path, 'b.png');
    File(imgPath).writeAsBytesSync(base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII='));
    File(img2).writeAsBytesSync(base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII='));
    final book = BookModel(title: 'Read', path: dir.path, language: 'en', pages: [imgPath, img2]);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReaderScreen(book: book),
    ));
    final btn = find.byIcon(Icons.filter_2);
    expect(btn, findsOneWidget);
    await tester.tap(btn);
    await tester.pump();
    expect(find.byIcon(Icons.filter_1), findsOneWidget);
  });

  testWidgets('shows bookmark toggle and slider', (tester) async {
    final dir = Directory.systemTemp.createTempSync();
    final imgPath = p.join(dir.path, 'a.png');
    File(imgPath).writeAsBytesSync(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII='));
    final book = BookModel(title: 'Read', path: dir.path, language: 'en', pages: [imgPath]);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReaderScreen(book: book),
    ));
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('opens bookmarks screen from menu', (tester) async {
    final dir = Directory.systemTemp.createTempSync();
    final imgPath = p.join(dir.path, 'a.png');
    File(imgPath).writeAsBytesSync(base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII='));
    final book = BookModel(title: 'Read', path: dir.path, language: 'en', pages: [imgPath]);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReaderScreen(book: book),
    ));

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bookmarks'));
    await tester.pumpAndSettle();

    expect(find.text('No bookmarks'), findsOneWidget);
  });

  testWidgets('tapping right edge changes the page', (tester) async {
    final dir = Directory.systemTemp.createTempSync();
    final img1 = p.join(dir.path, 'a.png');
    final img2 = p.join(dir.path, 'b.png');
    final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=');
    File(img1).writeAsBytesSync(bytes);
    File(img2).writeAsBytesSync(bytes);
    final book = BookModel(title: 'Read', path: dir.path, language: 'en', pages: [img1, img2]);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReaderScreen(book: book),
    ));

    Slider slider = tester.widget(find.byType(Slider));
    expect(slider.value, 0);

    await tester.tap(find.byKey(const Key('next_page_zone')));
    await tester.pumpAndSettle();

    slider = tester.widget(find.byType(Slider));
    expect(slider.value, 1);
  });
}
