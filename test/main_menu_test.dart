import 'package:flutter/material.dart';
import 'package:mana_reader/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mana_reader/models/book_model.dart';
import 'package:mana_reader/screens/main_menu.dart';

void main() {
  testWidgets('shows continue reading when history exists', (tester) async {
    final books = [BookModel(title: 'A', path: '/tmp/a', language: 'en')];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MainMenu(fetchHistoryBooks: () async => books),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('continue_reading_button')), findsOneWidget);
  });
}
