import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/book_model.dart';

/// Lists bookmarked pages for a book and returns the selected page index.
class BookmarksScreen extends StatelessWidget {
  final BookModel book;
  const BookmarksScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final id = book.id;
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: id == null
          ? const Center(child: Text('No bookmarks'))
          : FutureBuilder<List<int>>(
              future: DbHelper.instance.fetchBookmarks(id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pages = snapshot.data!;
                if (pages.isEmpty) {
                  return const Center(child: Text('No bookmarks'));
                }
                return ListView.builder(
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final p = pages[index];
                    return ListTile(
                      title: Text('Page ${p + 1}') ,
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                );
              },
            ),
    );
  }
}
