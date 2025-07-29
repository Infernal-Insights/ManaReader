import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/book_model.dart';
import 'reader_screen.dart';
import 'dart:io';

/// Lists books sorted by recent reading history.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  final Map<String, Future<double>> _progressCache = {};

  Future<List<BookModel>> _fetchHistory() {
    return DbHelper.instance.fetchHistoryBooks();
  }

  Future<double> _progressFor(BookModel book) {
    return _progressCache[book.path] ??= _loadProgress(book);
  }

  Future<double> _loadProgress(BookModel book) async {
    int count = book.pages.length;
    if (count == 0) {
      final dir = Directory(book.path);
      if (!await dir.exists()) return 0;
      try {
        final files = await dir
            .list(recursive: true)
            .where((e) => e is File && _isImage(e.path))
            .toList();
        files.sort();
        count = files.length;
      } catch (_) {
        return 0;
      }
    }
    if (count == 0) return 0;
    final progress = book.lastPage / count;
    return progress.clamp(0, 1).toDouble();
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: FutureBuilder<List<BookModel>>(
        future: _fetchHistory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final books = snapshot.data!;
          if (books.isEmpty) {
            return const Center(child: Text('No history'));
          }
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                title: Text(book.title),
                subtitle: FutureBuilder<double>(
                  future: _progressFor(book),
                  builder: (context, snap) {
                    final value = snap.data ?? 0.0;
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 4,
                      backgroundColor: Colors.black26,
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
