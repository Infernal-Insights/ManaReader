import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/book_model.dart';
import 'reader_screen.dart';

/// Lists books sorted by recent reading history.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<List<BookModel>> _fetchHistory() {
    return DbHelper.instance.fetchHistoryBooks();
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
