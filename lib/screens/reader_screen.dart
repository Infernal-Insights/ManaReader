import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../database/db_helper.dart';
import '../l10n/app_localizations.dart';
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
  final Set<int> _preloadErrors = {};
  int _currentPage = 0;
  Set<int> _bookmarks = {};
  bool _showUI = true;
  double? _lastWidth;

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
        _precache(_currentPage);
      });
    } else {
      _precache(_currentPage);
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
    _precache(index + 1);
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
    if (!mounted) return;
    final paths = _pagesForIndex(index);
    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      if (path.isEmpty) continue;
      final pageNumber = _doublePage ? index * 2 + i + 1 : index + 1;
      if (_preloadErrors.contains(pageNumber)) continue;
      precacheImage(FileImage(File(path)), context).catchError((e, st) {
        debugPrint('Failed to preload image at $path: $e');
        debugPrintStack(stackTrace: st);
        if (!mounted) return;
        setState(() {
          _preloadErrors.add(pageNumber);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.pageLoadFailed(pageNumber),
            ),
          ),
        );
      });
    }
  }

  Future<void> _loadPages() async {
    final dir = Directory(_book.path);
    late final List<String> pages;
    try {
      pages = await dir
          .list(recursive: true)
          .where((e) => e is File && _isImage(e.path))
          .map((e) => e.path)
          .toList();
    } catch (e, st) {
      debugPrint('Failed to read pages from ${_book.path}: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to load pages')));
      return;
    }
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
    final related = await db.fetchBooks(
      author: _book.author,
      unread: true,
      orderBy: 'title',
    );
    BookModel? next;
    for (final b in related) {
      if (b.id != id) {
        next = b;
        break;
      }
    }
    final unread = await db.fetchBooks(unread: true, orderBy: 'title');
    final others = unread.where((b) => b.id != id).toList();
    others.shuffle();
    final random = others.isNotEmpty ? others.first : null;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.endOfBook),
        content: Text(AppLocalizations.of(context)!.chooseOption),
        actions: [
          if (next != null)
            TextButton(
              onPressed: () {
                context.pop();
                context.pushReplacement('/reader', extra: next!);
              },
              child: Text(AppLocalizations.of(context)!.nextRelated),
            ),
          if (random != null)
            TextButton(
              onPressed: () {
                context.pop();
                context.pushReplacement('/reader', extra: random);
              },
              child: Text(AppLocalizations.of(context)!.randomUnread),
            ),
          TextButton(
            onPressed: () {
              context.pop();
              context.pop();
            },
            child: Text(AppLocalizations.of(context)!.library),
          ),
        ],
      ),
    );
  }

  Future<void> _openBookmarks() async {
    final page = await context.push<int>('/bookmarks', extra: _book);
    if (page != null && mounted) {
      final index = _doublePage ? (page / 2).floor() : page;
      _controller.jumpToPage(index);
      setState(() {
        _currentPage = index;
      });
    }
  }

  void _onImageError(int index) {
    if (!mounted) return;
    if (_currentPage == index) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildPage(int index) {
    final pages = _pagesForIndex(index);
    final orientation = MediaQuery.of(context).orientation;
    final fit =
        orientation == Orientation.portrait ? BoxFit.contain : BoxFit.fitWidth;
    if (pages.length == 1) {
      return _ZoomableImage(
        path: pages.first,
        fit: fit,
        onError: () => _onImageError(index),
      );
    }
    return Row(
      children: [
        Expanded(
          child: _ZoomableImage(
            path: pages[0],
            fit: fit,
            onError: () => _onImageError(index),
          ),
        ),
        if (pages.length > 1)
          Expanded(
            child: _ZoomableImage(
              path: pages[1],
              fit: fit,
              onError: () => _onImageError(index),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width > 600;
        if (_lastWidth == null || (width > 600) != (_lastWidth! > 600)) {
          if (_doublePage != isWide) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _doublePage = isWide;
                final newPage = (_currentPage / (_doublePage ? 2 : 1)).floor();
                _controller = PageController(initialPage: newPage);
                _currentPage = newPage;
              });
            });
          }
        }
        _lastWidth = width;

        return Scaffold(
          appBar: _showUI
              ? AppBar(
                  title: Text(_book.title),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isRtl
                            ? Icons.format_textdirection_r_to_l
                            : Icons.format_textdirection_l_to_r,
                      ),
                      onPressed: () => setState(() => _isRtl = !_isRtl),
                    ),
                    IconButton(
                      icon: Icon(
                        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      ),
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
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'bookmarks') _openBookmarks();
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'bookmarks',
                          child: Text(AppLocalizations.of(context)!.bookmarks),
                        ),
                      ],
                    ),
                  ],
                )
              : null,
          body: Directionality(
            textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: _pageCount,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) => _buildPage(index),
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          key: const Key('previous_page_zone'),
                          behavior: HitTestBehavior.translucent,
                          onTap: () => _controller.previousPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                      const Expanded(child: SizedBox.shrink()),
                      Expanded(
                        child: GestureDetector(
                          key: const Key('next_page_zone'),
                          behavior: HitTestBehavior.translucent,
                          onTap: () => _controller.nextPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(() => _showUI = !_showUI),
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
      },
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final String path;
  final BoxFit fit;
  final VoidCallback? onError;
  const _ZoomableImage({required this.path, required this.fit, this.onError});

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
        child: Image.file(
          File(widget.path),
          fit: widget.fit,
          errorBuilder: (_, __, ___) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onError?.call();
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
