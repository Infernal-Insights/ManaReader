import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'database/db_helper.dart';
import 'l10n/app_localizations.dart';
import 'models/book_model.dart';
import 'screens/book_detail_screen.dart';
import 'screens/bookmarks_screen.dart';
import 'screens/history_screen.dart';
import 'screens/library_screen.dart';
import 'screens/main_menu.dart';
import 'screens/reader_screen.dart';

void main() => runApp(const ManaReaderApp());

class ManaReaderApp extends StatefulWidget {
  const ManaReaderApp({super.key});

  @override
  State<ManaReaderApp> createState() => _ManaReaderAppState();
}

class _ManaReaderAppState extends State<ManaReaderApp> {
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const MainMenu()),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(path: '/history', builder: (context, state) => HistoryScreen()),
      GoRoute(
        path: '/reader',
        builder: (context, state) {
          final book = state.extra as BookModel;
          return ReaderScreen(book: book);
        },
      ),
      GoRoute(
        path: '/book',
        builder: (context, state) {
          final book = state.extra as BookModel;
          return BookDetailScreen(book: book);
        },
      ),
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) {
          final book = state.extra as BookModel;
          return BookmarksScreen(book: book);
        },
      ),
    ],
  );
  @override
  void dispose() {
    DbHelper.instance.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: _router,
    );
  }
}
