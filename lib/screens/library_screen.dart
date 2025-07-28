import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/book_model.dart';

import '../importers/importer_factory.dart';
import 'package:file_picker/file_picker.dart';


/// Displays the list of imported books.
class LibraryScreen extends StatefulWidget {
  final Future<List<BookModel>> Function({
    List<String>? tags,
    String? author,
    bool? unread,
  })? fetchBooks;

  const LibraryScreen({super.key, this.fetchBooks});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<BookModel>> _books;
  List<String> _tags = [];
  List<String> _authors = [];
  String? _selectedTag;
  String? _selectedAuthor;
  bool _showUnread = false;
  bool _isGrid = true;

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
        tags: _selectedTag != null ? [_selectedTag!] : null,
        author: _selectedAuthor,
        unread: _showUnread ? true : null,
      );
    });
  }

  Future<void> _initFilters() async {
    final tags = await DbHelper.instance.fetchAllTags();
    final authors = await DbHelper.instance.fetchAllAuthors();
    setState(() {
      _tags = tags;
      _authors = authors;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
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
            return const Center(child: Text('No books imported'));
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
                    MaterialPageRoute(
                      builder: (_) => ReaderScreen(book: book),
                    ),
                  ),
                  child: Container(
                    color: Colors.grey.shade800,
                    alignment: Alignment.center,
                    child: Text(
                      book.title,
                      textAlign: TextAlign.center,
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReaderScreen(book: book),
                    ),
                  ),
                );
              },
            );
          }

          return Column(
            children: [
              if (_tags.isNotEmpty || _authors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      if (_tags.isNotEmpty)
                        DropdownButton<String?>(
                          hint: const Text('Tag'),
                          value: _selectedTag,
                          items: [
                            const DropdownMenuItem<String?>(
                                value: null, child: Text('All')),
                            ..._tags.map(
                              (e) => DropdownMenuItem<String?>(
                                  value: e, child: Text(e)),
                            ),
                          ],
                          onChanged: (value) {
                            _selectedTag = value;
                            _loadBooks();
                          },
                        ),
                      const SizedBox(width: 8),
                      if (_authors.isNotEmpty)
                        DropdownButton<String?>(
                          hint: const Text('Author'),
                          value: _selectedAuthor,
                          items: [
                            const DropdownMenuItem<String?>(
                                value: null, child: Text('All')),
                            ..._authors.map(
                              (e) => DropdownMenuItem<String?>(
                                  value: e, child: Text(e)),
                            ),
                          ],
                          onChanged: (value) {
                            _selectedAuthor = value;
                            _loadBooks();
                          },
                        ),
                      const SizedBox(width: 8),
                      Row(
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
                          const Text('Unread')
                        ],
                      )
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

  Future<void> _pickAndImport() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    try {
      final importer = ImporterFactory.fromPath(path);
      final book = await importer.import(path);
      await DbHelper.instance.insertBook(book);
      _loadBooks();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }
}
