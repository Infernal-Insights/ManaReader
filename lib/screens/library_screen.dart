import 'dart:io';

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../database/db_helper.dart';
import '../models/book_model.dart';

import '../import/importer.dart';
import '../import/sync_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'book_detail_screen.dart';
import 'history_screen.dart';

/// Displays the list of imported books.
class LibraryScreen extends StatefulWidget {
  final Future<List<BookModel>> Function({
    List<String>? tags,
    String? author,
    String? language,
    bool? unread,
    String? query,
    String? orderBy,
  })?
  fetchBooks;

  const LibraryScreen({super.key, this.fetchBooks});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<BookModel>> _books;
  List<String> _tags = [];
  List<String> _authors = [];
  List<String> _languages = [];
  final Set<String> _selectedTags = <String>{};
  final Set<String> _selectedAuthors = <String>{};
  String? _selectedLanguage;
  bool _showUnread = false;
  bool _showFavorites = false;
  bool _isGrid = true;
  String _searchQuery = '';
  String _sortOrder = 'title';

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
  }

  @override
  void initState() {
    super.initState();

    _loadBooks();
    _initFilters();
  }

  void _loadBooks() {
    setState(() {
      final fetch = widget.fetchBooks ?? DbHelper.instance.fetchBooks;
      _books = fetch(
        tags: _selectedTags.isNotEmpty ? _selectedTags.toList() : null,
        author: _selectedAuthors.isNotEmpty ? _selectedAuthors.first : null,
        language: _selectedLanguage,
        unread: _showUnread ? true : null,
        favorite: _showFavorites ? true : null,
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        orderBy: _sortOrder,
      );
    });
  }

  Future<void> _initFilters() async {
    final tags = await DbHelper.instance.fetchAllTags();
    final authors = await DbHelper.instance.fetchAllAuthors();
    final languages = await DbHelper.instance.fetchAllLanguages();
    if (!mounted) return;
    setState(() {
      _tags = tags;
      _authors = authors;
      _languages = languages;
    });
  }

  final Map<String, Future<String?>> _thumbCache = {};

  final Map<String, Future<double>> _progressCache = {};

  Future<String?> _thumbnailFor(BookModel book) {
    return _thumbCache[book.path] ??= _loadThumbnail(book);
  }

  Future<double> _progressFor(BookModel book) {
    return _progressCache[book.path] ??= _loadProgress(book);
  }

  Future<String?> _loadThumbnail(BookModel book) async {
    if (book.pages.isNotEmpty) {
      return book.pages.first;
    }
    final dir = Directory(book.path);
    if (!await dir.exists()) return null;
    try {
      final files = await dir
          .list(recursive: true)
          .where((e) => e is File && _isImage(e.path))
          .map((e) => e.path)
          .toList();
      files.sort();
      return files.isNotEmpty ? files.first : null;
    } catch (_) {
      return null;
    }
  }

  Future<double> _loadProgress(BookModel book) async {
    final count = book.pages.length;
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
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.searchTitle,
            border: InputBorder.none,
          ),
          onChanged: (v) {
            _searchQuery = v;
            _loadBooks();
          },
        ),
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortOrder,
              items: [
                DropdownMenuItem(
                    value: 'title',
                    child: Text(AppLocalizations.of(context)!.sortTitle)),
                DropdownMenuItem(
                    value: 'author',
                    child: Text(AppLocalizations.of(context)!.sortAuthor)),
                DropdownMenuItem(
                    value: 'recent',
                    child: Text(AppLocalizations.of(context)!.sortRecent)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortOrder = value);
                  _loadBooks();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _openHistory,
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncDirectory,
          ),
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list : Icons.grid_on),
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
      ),
      body: FutureBuilder<List<BookModel>>(
        future: _books,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final books = snapshot.data!;
          if (books.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noBooks));
          }
          Widget listWidget;
          if (_isGrid) {
            listWidget = GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReaderScreen(book: book)),
                  ),
                  onLongPress: () => _confirmDelete(book),
                  child: GridTile(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FutureBuilder<String?>(
                          future: _thumbnailFor(book),
                          builder: (context, snap) {
                            if (snap.connectionState != ConnectionState.done) {
                              return Container(
                                color: Colors.grey.shade800,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(),
                              );
                            }
                            final path = snap.data;
                            if (path != null) {
                              return Image.file(File(path), fit: BoxFit.cover);
                            }
                            return Container(
                              color: Colors.grey.shade800,
                              alignment: Alignment.center,
                              child: const Icon(Icons.book, size: 48),
                            );
                          },
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: IconButton(
                            icon: Icon(
                              book.favorite ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () async {
                              if (book.id != null) {
                                await DbHelper.instance
                                    .toggleFavorite(book.id!, !book.favorite);
                                _loadBooks();
                              }
                            },
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: FutureBuilder<double>(
                            future: _progressFor(book),
                            builder: (context, progressSnap) {
                              final value = progressSnap.data ?? 0.0;
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 4,
                                backgroundColor: Colors.black26,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: FutureBuilder<double>(
                            future: _progressFor(book),
                            builder: (context, snap) {
                              final value = snap.data ?? 0.0;
                              final percent = (value * 100).round();
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                color: Colors.black54,
                                child: Text(
                                  '$percent%',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    footer: GridTileBar(
                      backgroundColor: Colors.black54,
                      title: Text(book.title, textAlign: TextAlign.center),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') _openDetails(book);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                              value: 'edit',
                              child: Text(AppLocalizations.of(context)!.edit)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            listWidget = ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  title: Text(book.title),
                  subtitle: Text(book.author),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder<double>(
                        future: _progressFor(book),
                        builder: (context, snap) {
                          final value = snap.data ?? 0.0;
                          final percent = (value * 100).round();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            color: Colors.black54,
                            child: Text(
                              '$percent%',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          book.favorite ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () async {
                          if (book.id != null) {
                            await DbHelper.instance
                                .toggleFavorite(book.id!, !book.favorite);
                            _loadBooks();
                          }
                        },
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') _openDetails(book);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                              value: 'edit',
                              child: Text(AppLocalizations.of(context)!.edit)),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReaderScreen(book: book)),
                  ),
                  onLongPress: () => _confirmDelete(book),
                );
              },
            );
          }

          return Column(
            children: [
              if (_tags.isNotEmpty || _authors.isNotEmpty || _languages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (_tags.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: [
                            FilterChip(
                              label: Text(AppLocalizations.of(context)!.clear),
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) {
                                setState(() => _selectedTags.clear());
                                _loadBooks();
                              },
                            ),
                            ..._tags.map(
                              (tag) => FilterChip(
                                label: Text(tag),
                                selected: _selectedTags.contains(tag),
                                onSelected: (v) {
                                  setState(() {
                                    if (v) {
                                      _selectedTags.add(tag);
                                    } else {
                                      _selectedTags.remove(tag);
                                    }
                                  });
                                  _loadBooks();
                                },
                              ),
                            ),
                          ],
                        ),
                      if (_authors.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: [
                            FilterChip(
                              label: Text(AppLocalizations.of(context)!.clear),
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) {
                                setState(() => _selectedAuthors.clear());
                                _loadBooks();
                              },
                            ),
                            ..._authors.map(
                              (author) => FilterChip(
                                label: Text(author),
                                selected: _selectedAuthors.contains(author),
                                onSelected: (v) {
                                  setState(() {
                                    if (v) {
                                      _selectedAuthors.add(author);
                                    } else {
                                      _selectedAuthors.remove(author);
                                    }
                                  });
                                  _loadBooks();
                                },
                              ),
                            ),
                          ],
                        ),
                      if (_languages.isNotEmpty)
                        DropdownButton<String?>(
                          hint: Text(AppLocalizations.of(context)!.language),
                          value: _selectedLanguage,
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(AppLocalizations.of(context)!.all),
                            ),
                            ..._languages.map(
                              (e) => DropdownMenuItem<String?>(
                                value: e,
                                child: Text(e),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            _selectedLanguage = value;
                            _loadBooks();
                          },
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _showUnread,
                            onChanged: (v) {
                              setState(() {
                                _showUnread = v ?? false;
                              });
                              _loadBooks();
                            },
                          ),
                          Text(AppLocalizations.of(context)!.unread),
                          IconButton(
                            icon: Icon(
                                _showFavorites ? Icons.star : Icons.star_border),
                            onPressed: () {
                              setState(() => _showFavorites = !_showFavorites);
                              _loadBooks();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Expanded(child: listWidget),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickAndImport,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(BookModel book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteBook),
        content: Text(
            AppLocalizations.of(context)!.deleteConfirm(title: book.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DbHelper.instance.deleteBook(book.id!);
      try {
        final dir = Directory(book.path);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {}
      if (mounted) _loadBooks();
    }
  }

  Future<void> _openDetails(BookModel book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
    if (mounted) _loadBooks();
  }

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    try {
      final importer = Importer();
      await importer.importPath(path);
      _loadBooks();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.importFailed(error: e.toString()),
            ),
          ),
        );
      }
    }
  }

  Future<void> _syncDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return;
    try {
      await syncDirectoryPath(path);
      if (mounted) _loadBooks();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.importFailed(error: e.toString()),
            ),
          ),
        );
      }
    }
  }
}
