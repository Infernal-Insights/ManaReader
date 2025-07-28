import 'package:flutter/material.dart';
import '../models/book_model.dart';

class ReaderScreen extends StatelessWidget {
  final BookModel book;

  const ReaderScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.title)),
      body: Center(
        child: Text('Reader for ${book.title}'),
      ),
    );
  }
}
