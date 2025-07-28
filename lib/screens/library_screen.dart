import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/book_model.dart';
import '../importers/importer_factory.dart';
import 'package:file_picker/file_picker.dart';

/// Displays the list of imported books.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<BookModel>> _books;

  @override
  void initState() {
    super.initState();
    _books = DbHelper.instance.fetchBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
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
          return GridView.builder(
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
                onTap: () {},
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
      setState(() {
        _books = DbHelper.instance.fetchBooks();
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }
}
