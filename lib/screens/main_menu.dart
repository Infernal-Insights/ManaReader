import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/book_model.dart';
import '../l10n/app_localizations.dart';
import 'history_screen.dart';
import 'library_screen.dart';
import 'reader_screen.dart';

/// Simple start screen offering navigation to major sections.
class MainMenu extends StatelessWidget {
  final Future<List<BookModel>> Function()? fetchHistoryBooks;

  const MainMenu({super.key, this.fetchHistoryBooks});

  Future<BookModel?> _loadLastRead() async {
    final fetch = fetchHistoryBooks ?? DbHelper.instance.fetchHistoryBooks;
    final books = await fetch();
    return books.isNotEmpty ? books.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.appTitle)),
      body: Center(
        child: FutureBuilder<BookModel?>(
          future: _loadLastRead(),
          builder: (context, snapshot) {
            final book = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (book != null)
                  ElevatedButton(
                    key: const Key('continue_reading_button'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReaderScreen(book: book),
                      ),
                    ),
                    child:
                        Text(AppLocalizations.of(context)!.continueReading),
                  ),
                if (book != null) const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LibraryScreen()),
                  ),
                  child: Text(AppLocalizations.of(context)!.library),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HistoryScreen()),
                  ),
                  child: Text(AppLocalizations.of(context)!.history),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
