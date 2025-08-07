import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../database/db_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/book_model.dart';

/// Lists books sorted by recent reading history.
class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  final Map<String, Future<double>> _progressCache = {};
  final Map<String, Future<String?>> _thumbCache = {};

  Future<List<BookModel>> _fetchHistory() {
    return DbHelper.instance.fetchHistoryBooks();
  }

  Future<double> _progressFor(BookModel book) {
    return _progressCache[book.path] ??= _loadProgress(book);
  }

  Future<String?> _thumbnailFor(BookModel book) {
    return _thumbCache[book.path] ??= _loadThumbnail(book);
  }

  Future<double> _loadProgress(BookModel book) async {
    final count = book.pages.length;
    if (count == 0) return 0;
    final progress = book.lastPage / count;
    return progress.clamp(0, 1).toDouble();
  }

  Future<String?> _loadThumbnail(BookModel book) async {
    if (book.pages.isNotEmpty) {
      return book.pages.first;
    }
    final dir = Directory(book.path);
    if (!await dir.exists()) return null;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && _isImage(entity.path)) {
          return entity.path;
        }
      }
    } catch (e) {
      debugPrint('Failed to load thumbnail for ${book.path}: $e');
    }
    return null;
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
          final recent = books.take(6).toList();
          return ListView.builder(
            itemCount: recent.length,
            itemBuilder: (context, index) {
              final book = recent[index];
              return ListTile(
                leading: FutureBuilder<String?>(
                  future: _thumbnailFor(book),
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return Container(
                        width: 50,
                        height: 70,
                        color: Colors.grey.shade800,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      );
                    }
                    if (snap.hasError) {
                      return Container(
                        width: 50,
                        height: 70,
                        color: Colors.grey.shade800,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image),
                      );
                    }
                    final path = snap.data;
                    if (path != null) {
                      return Image.file(File(path), width: 50, height: 70, fit: BoxFit.cover);
                    }
                    return Container(
                      width: 50,
                      height: 70,
                      color: Colors.grey.shade800,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
                title: Text(book.title),
                subtitle: book.author.isNotEmpty ? Text(book.author) : null,
                trailing: FutureBuilder<double>(
                  future: _progressFor(book),
                  builder: (context, snap) {
                    final value = snap.data ?? 0.0;
                    final percent = (value * 100).round();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      color: Colors.black54,
                      child: Text(
                        '$percent%',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    );
                  },
                ),
                onTap: () => context.push('/reader', extra: book),
              );
            },
          );
        },
      ),
    );
  }
}
