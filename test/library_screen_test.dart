// Library screen tests updated for new architecture.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mana_reader/core/db/database.dart';
import 'package:mana_reader/features/library/library_screen.dart';
import 'package:mana_reader/features/reader/reader_controller.dart';

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows empty state when library is empty', (tester) async {
    final db = _makeDb();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const LibraryScreen()),
        GoRoute(path: '/sources/add-local', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/library/shelves', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/reader/:id', builder: (_, __) => const Scaffold()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();
    expect(find.text('Your library is empty'), findsOneWidget);
    await db.close();
  });

  testWidgets('shows series cards when library has items', (tester) async {
    final db = _makeDb();
    await db.seriesDao.upsert(SeriesCompanion(
      id: const Value('s1'),
      title: const Value('Berserk'),
      sortKey: const Value('berserk'),
    ));

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const LibraryScreen()),
        GoRoute(path: '/sources/add-local', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/library/shelves', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/reader/:id', builder: (_, __) => const Scaffold()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pump();
    expect(find.text('Berserk'), findsOneWidget);
    await db.close();
  });
}
