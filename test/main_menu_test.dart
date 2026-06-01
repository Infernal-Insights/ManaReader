// Main menu tests updated for new architecture.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mana_reader/core/db/database.dart';
import 'package:mana_reader/features/home/home_screen.dart';
import 'package:mana_reader/features/reader/reader_controller.dart';
import 'package:mana_reader/app/theme.dart';

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HomeScreen renders without error', (tester) async {
    final db = _makeDb();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/sources', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/library', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/reader/:id', builder: (_, __) => const Scaffold()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(
          theme: ManaTheme.dark,
          routerConfig: router,
        ),
      ),
    );

    await tester.pump();
    expect(find.text('ManaReader'), findsOneWidget);
    await db.close();
  });
}
