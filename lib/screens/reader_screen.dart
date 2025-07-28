import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/book_model.dart';

/// Displays the pages of a book using [PageView] and remembers the last page
/// read. Supports left-to-right or right-to-left reading direction, pinch zoom
/// and double-tap zoom via [InteractiveViewer].
class ReaderScreen extends StatefulWidget {
  final BookModel book;

  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _controller;
  bool _isRtl = false;
  bool _doublePage = false;
  bool _preload = true;
  int _currentPage = 0;

  int get _pageCount => _doublePage
      ? (widget.book.pages.length / 2).ceil()
      : widget.book.pages.length;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.lastPage;
    _controller = PageController(initialPage: _currentPage);
    if (_preload) _precache(_currentPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) async {
    _currentPage = index;
    final id = widget.book.id;
    if (id != null) {
      await DbHelper.instance.updateProgress(id, _pageToProgress(index));
    }
    if (_preload) _precache(index + 1);
    if (index >= _pageCount - 1) {
      _showEndDialog();
    }
  }

  int _pageToProgress(int index) => _doublePage ? index * 2 : index;

  List<String> _pagesForIndex(int index) {
    if (_doublePage) {
      final first = index * 2;
      final second = first + 1;
      return [
        if (first < widget.book.pages.length) widget.book.pages[first],
        if (second < widget.book.pages.length) widget.book.pages[second],
      ];
    }
    return [if (index < widget.book.pages.length) widget.book.pages[index]];
  }

  void _precache(int index) {
    if (!_preload || !mounted) return;
    for (final path in _pagesForIndex(index)) {
      if (path.isNotEmpty) {
        precacheImage(FileImage(File(path)), context);
      }
    }
  }

  Future<void> _showEndDialog() async {
    final id = widget.book.id;
    if (id == null) return;

    final db = DbHelper.instance;
    final related =
        await db.fetchBooks(author: widget.book.author, unread: true);
    BookModel? next;
    for (final b in related) {
      if (b.id != id) {
        next = b;
        break;
      }
    }
    final unread = await db.fetchBooks(unread: true);
    final others = unread.where((b) => b.id != id).toList();
    others.shuffle();
    final random = others.isNotEmpty ? others.first : null;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End of book'),
        content: const Text('Choose an option'),
        actions: [
          if (next != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => ReaderScreen(book: next!)),
                );
              },
              child: const Text('Next Related'),
            ),
          if (random != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ReaderScreen(book: random!)),
                );
              },
              child: const Text('Random Unread'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Library'),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    final pages = _pagesForIndex(index);
    if (pages.length == 1) {
      return _ZoomableImage(path: pages.first);
    }
    return Row(
      children: [
        Expanded(child: _ZoomableImage(path: pages[0])),
        if (pages.length > 1) Expanded(child: _ZoomableImage(path: pages[1])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          IconButton(
            icon: Icon(_isRtl
                ? Icons.format_textdirection_r_to_l
                : Icons.format_textdirection_l_to_r),
            onPressed: () => setState(() => _isRtl = !_isRtl),
          ),
          IconButton(
            icon: Icon(_doublePage ? Icons.filter_1 : Icons.filter_2),
            onPressed: () => setState(() {
              _doublePage = !_doublePage;
              final newPage = (_currentPage / (_doublePage ? 2 : 1)).floor();
              _controller = PageController(initialPage: newPage);
              _currentPage = newPage;
            }),
          ),
        ],
      ),
      body: Directionality(
        textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: PageView.builder(
          controller: _controller,
          itemCount: _pageCount,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) => _buildPage(index),
        ),
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final String path;
  const _ZoomableImage({required this.path});

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    setState(() {
      final m = _controller.value;
      if (m != Matrix4.identity()) {
        _controller.value = Matrix4.identity();
      } else {
        _controller.value = Matrix4.identity()..scale(2.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: InteractiveViewer(
        transformationController: _controller,
        child: Image.file(File(widget.path), fit: BoxFit.contain),
      ),
    );
  }
}
