import 'dart:io';

import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/book_model.dart';

/// Displays the pages of a book with zoom and swipe gestures.
class ReaderScreen extends StatefulWidget {
  final BookModel book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final TransformationController _controller = TransformationController();
  late final PageController _pageController;
  late final List<File> _pages;
  bool _rtl = false;

  @override
  void initState() {
    super.initState();
    final dir = Directory(widget.book.path);
    _pages = dir
        .listSync()
        .whereType<File>()
        .where((f) => _isImage(f.path))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    _pageController = PageController(initialPage: widget.book.lastPage);
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  void _onPageChanged(int index) {
    _controller.value = Matrix4.identity();
    if (widget.book.id != null) {
      DbHelper.instance.updateProgress(widget.book.id!, index);
    }
  }

  void _toggleDirection() => setState(() => _rtl = !_rtl);

  void _handleDoubleTap() {
    final zoomed = _controller.value.getMaxScaleOnAxis() > 1;
    _controller.value =
        zoomed ? Matrix4.identity() : Matrix4.identity()..scale(2.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          IconButton(
            icon: Icon(
                _rtl ? Icons.format_textdirection_l_to_r : Icons.format_textdirection_r_to_l),
            onPressed: _toggleDirection,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        reverse: _rtl,
        itemCount: _pages.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return GestureDetector(
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _controller,
              panEnabled: true,
              minScale: 1,
              maxScale: 5,
              child: Image.file(_pages[index], fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
