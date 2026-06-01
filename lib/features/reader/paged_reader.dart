import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'reader_controller.dart';
import 'reader_settings.dart';

/// Horizontal paged reader with LTR/RTL support and tap zones.
class PagedReader extends StatefulWidget {
  final ReaderState readerState;
  final Future<Uint8List?> Function(int index) getPageBytes;
  final VoidCallback? onTapLeft;
  final VoidCallback? onTapRight;
  final VoidCallback? onTapCenter;

  const PagedReader({
    super.key,
    required this.readerState,
    required this.getPageBytes,
    this.onTapLeft,
    this.onTapRight,
    this.onTapCenter,
  });

  @override
  State<PagedReader> createState() => _PagedReaderState();
}

class _PagedReaderState extends State<PagedReader> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.readerState.currentPage,
    );
  }

  @override
  void didUpdateWidget(PagedReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newPage = widget.readerState.currentPage;
    if (_pageController.hasClients &&
        _pageController.page?.round() != newPage) {
      _pageController.jumpToPage(newPage);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isRtl =>
      widget.readerState.settings.direction == ReadingDirection.rtl;

  @override
  Widget build(BuildContext context) {
    final state = widget.readerState;
    return GestureDetector(
      onTapUp: (details) {
        final width = context.size!.width;
        final x = details.localPosition.dx;
        if (x < width * 0.25) {
          _isRtl ? widget.onTapRight?.call() : widget.onTapLeft?.call();
        } else if (x > width * 0.75) {
          _isRtl ? widget.onTapLeft?.call() : widget.onTapRight?.call();
        } else {
          widget.onTapCenter?.call();
        }
      },
      child: PageView.builder(
        controller: _pageController,
        reverse: _isRtl,
        itemCount: state.pageCount,
        physics: const ClampingScrollPhysics(),
        itemBuilder: (context, index) => _PageView(
          index: index,
          getPageBytes: widget.getPageBytes,
        ),
      ),
    );
  }
}

class _PageView extends StatefulWidget {
  final int index;
  final Future<Uint8List?> Function(int) getPageBytes;

  const _PageView({required this.index, required this.getPageBytes});

  @override
  State<_PageView> createState() => _PageViewState();
}

class _PageViewState extends State<_PageView> {
  late Future<Uint8List?> _future;
  final _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    _future = widget.getPageBytes(widget.index);
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _PageSkeleton();
        }
        if (snap.hasError || snap.data == null) {
          return const Center(
            child: Icon(Icons.broken_image_outlined, size: 64, color: Colors.white30),
          );
        }
        return InteractiveViewer(
          transformationController: _transformController,
          minScale: 1.0,
          maxScale: 5.0,
          child: Center(
            child: Image.memory(
              snap.data!,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        );
      },
    );
  }
}

class _PageSkeleton extends StatefulWidget {
  const _PageSkeleton();

  @override
  State<_PageSkeleton> createState() => _PageSkeletonState();
}

class _PageSkeletonState extends State<_PageSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0.3, end: 0.6).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        color: Colors.white.withOpacity(_anim.value * 0.05),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
