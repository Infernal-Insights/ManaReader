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
  late BookModel _book;
  bool _isRtl = false;
  bool _doublePage = false;
  bool _preload = true;
  int _currentPage = 0;
  Set<int> _bookmarks = {};
  bool _showUI = true;

  int get _pageCount =>
      _doublePage ? (_book.pages.length / 2).ceil() : _book.pages.length;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _currentPage = _book.lastPage;
    _controller = PageController(initialPage: _currentPage);
    _loadBookmarks();
    if (_book.pages.isEmpty) {
      _loadPages().then((_) {
        if (_preload) _precache(_currentPage);
      });
    } else {
      if (_preload) _precache(_currentPage);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) async {
    setState(() {
      _currentPage = index;
    });
    final id = _book.id;
    if (id != null) {
      await DbHelper.instance.updateProgress(id, _pageToProgress(index));
    }
    if (_preload) _precache(index + 1);
    if (index >= _pageCount - 1) {
      _showEndDialog();
    }
  }

  Future<void> _loadBookmarks() async {
    final id = _book.id;
    if (id == null) return;
    final pages = await DbHelper.instance.fetchBookmarks(id);
    if (!mounted) return;
    setState(() {
      _bookmarks = pages.toSet();
    });
  }

  bool get _isBookmarked => _bookmarks.contains(_pageToProgress(_currentPage));

  Future<void> _toggleBookmark() async {
    final id = _book.id;
    if (id == null) return;
    final page = _pageToProgress(_currentPage);
    if (_bookmarks.contains(page)) {
      await DbHelper.instance.removeBookmark(id, page);
      setState(() {
        _bookmarks.remove(page);
      });
    } else {
      await DbHelper.instance.addBookmark(id, page);
      setState(() {
        _bookmarks.add(page);
      });
    }
  }

  int _pageToProgress(int index) => _doublePage ? index * 2 : index;

  List<String> _pagesForIndex(int index) {
    if (_doublePage) {
      final first = index * 2;
      final second = first + 1;
      return [
        if (first < _book.pages.length) _book.pages[first],
        if (second < _book.pages.length) _book.pages[second],
      ];
    }
    return [if (index < _book.pages.length) _book.pages[index]];
  }

  void _precache(int index) {
    if (!_preload || !mounted) return;
    for (final path in _pagesForIndex(index)) {
      if (path.isNotEmpty) {
        precacheImage(FileImage(File(path)), context);
      }
    }
  }

  Future<void> _loadPages() async {
    final dir = Directory(_book.path);
    final pages = await dir
        .list(recursive: true)
        .where((e) => e is File && _isImage(e.path))
        .map((e) => e.path)
        .toList();
    pages.sort();
    if (!mounted) return;
    setState(() {
      _book = BookModel(
        id: _book.id,
        title: _book.title,
        path: _book.path,
        author: _book.author,
        language: _book.language,
        tags: _book.tags,
        lastPage: _book.lastPage,
        pages: pages,
      );
    });
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif');
  }

  Future<void> _showEndDialog() async {
    final id = _book.id;
    if (id == null) return;

    final db = DbHelper.instance;
    final related = await db.fetchBooks(author: _book.author, unread: true);
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
      appBar: _showUI
          ? AppBar(
              title: Text(_book.title),
              actions: [
                IconButton(
                  icon: Icon(_isRtl
                      ? Icons.format_textdirection_r_to_l
                      : Icons.format_textdirection_l_to_r),
                  onPressed: () => setState(() => _isRtl = !_isRtl),
                ),
                IconButton(
                  icon: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: _toggleBookmark,
                ),
                IconButton(
                  icon: Icon(_doublePage ? Icons.filter_1 : Icons.filter_2),
                  onPressed: () => setState(() {
                    _doublePage = !_doublePage;
                    final newPage =
                        (_currentPage / (_doublePage ? 2 : 1)).floor();
                    _controller = PageController(initialPage: newPage);
                    _currentPage = newPage;
                  }),
                ),
              ],
            )
          : null,
      body: Directionality(
        textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => setState(() => _showUI = !_showUI),
              child: PageView.builder(
                controller: _controller,
                itemCount: _pageCount,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) => _buildPage(index),
              ),
            ),
            if (_showUI)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Slider(
                  value: _currentPage.toDouble(),
                  min: 0,
                  max: max(0, _pageCount - 1).toDouble(),
                  onChanged: (v) {
                    setState(() {
                      _currentPage = v.round();
                      _controller.jumpToPage(_currentPage);
                    });
                  },
                ),
              ),
          ],
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
