import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

import '../database/db_helper.dart';
import '../models/book_model.dart';
import 'reader_screen.dart';

/// Lists books sorted by recent reading history.
class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  final Map<String, Future<double>> _progressCache = {};

  Future<List<BookModel>> _fetchHistory() {
    return DbHelper.instance.fetchHistoryBooks();
  }

  Future<double> _progressFor(BookModel book) {
    return _progressCache[book.path] ??= _loadProgress(book);
  }

  Future<double> _loadProgress(BookModel book) async {
    final count = book.pages.length;
    if (count == 0) return 0;
    final progress = book.lastPage / count;
    return progress.clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.historyTitle)),
      body: FutureBuilder<List<BookModel>>(
        future: _fetchHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final books = snapshot.data!;
          if (books.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noHistory));
          }
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                title: Text(book.title),
                trailing: FutureBuilder<double>(
                  future: _progressFor(book),
                  builder: (context, snap) {
                    final value = snap.data ?? 0.0;
                    final percent = (value * 100).round();
                    return Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      color: Colors.black54,
                      child: Text(
                        '$percent%',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    );
                  },
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReaderScreen(book: book),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
