import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.bookmarks)),
      body: id == null
          ? Center(child: Text(AppLocalizations.of(context)!.noBookmarks))
          : FutureBuilder<List<int>>(
              future: DbHelper.instance.fetchBookmarks(id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pages = snapshot.data!;
                if (pages.isEmpty) {
                  return Center(child: Text(AppLocalizations.of(context)!.noBookmarks));
                }
                return ListView.builder(
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    final p = pages[index];
                    return ListTile(
                      title: Text(AppLocalizations.of(context)!.pageWithNumber(page: p + 1)),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                );
              },
            ),
    );
  }
}
