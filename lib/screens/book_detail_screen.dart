import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/book_model.dart';

/// Displays and edits metadata for a [BookModel].
class BookDetailScreen extends StatefulWidget {
  final BookModel book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _languageController;
  late final TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _titleController = TextEditingController(text: book.title);
    _authorController = TextEditingController(text: book.author);
    _languageController = TextEditingController(text: book.language);
    _tagsController = TextEditingController(text: book.tags.join(', '));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _languageController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = BookModel(
      id: widget.book.id,
      title: _titleController.text,
      path: widget.book.path,
      author: _authorController.text,
      language: _languageController.text,
      tags: _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      lastPage: widget.book.lastPage,
      pages: widget.book.pages,
    );
    await DbHelper.instance.updateBook(updated);
    if (mounted) Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _authorController,
              decoration: const InputDecoration(labelText: 'Author'),
            ),
            TextField(
              controller: _languageController,
              decoration: const InputDecoration(labelText: 'Language'),
            ),
            TextField(
              controller: _tagsController,
              decoration:
                  const InputDecoration(labelText: 'Tags (comma separated)'),
            ),
          ],
        ),
      ),
    );
  }
}

