import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'reader_controller.dart';

/// Vertical-scroll (webtoon) reader.
class VerticalReader extends StatefulWidget {
  final ReaderState readerState;
  final Future<Uint8List?> Function(int index) getPageBytes;
  final void Function(int page)? onPageChanged;
  final VoidCallback? onTapCenter;

  const VerticalReader({
    super.key,
    required this.readerState,
    required this.getPageBytes,
    this.onPageChanged,
    this.onTapCenter,
  });

  @override
  State<VerticalReader> createState() => _VerticalReaderState();
}

class _VerticalReaderState extends State<VerticalReader> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.readerState;
    return GestureDetector(
      onTapUp: (details) {
        final width = context.size!.width;
        final x = details.localPosition.dx;
        // Tap center zone
        if (x > width * 0.25 && x < width * 0.75) {
          widget.onTapCenter?.call();
        }
      },
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.pageCount,
        cacheExtent: 2000,
        itemBuilder: (context, index) => _VerticalPageItem(
          index: index,
          getPageBytes: widget.getPageBytes,
        ),
      ),
    );
  }
}

class _VerticalPageItem extends StatefulWidget {
  final int index;
  final Future<Uint8List?> Function(int) getPageBytes;

  const _VerticalPageItem({required this.index, required this.getPageBytes});

  @override
  State<_VerticalPageItem> createState() => _VerticalPageItemState();
}

class _VerticalPageItemState extends State<_VerticalPageItem> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.getPageBytes(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const AspectRatio(
            aspectRatio: 0.7,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snap.hasError || snap.data == null) {
          return const AspectRatio(
            aspectRatio: 0.7,
            child: Center(
              child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.white30),
            ),
          );
        }
        return Image.memory(
          snap.data!,
          fit: BoxFit.fitWidth,
          width: double.infinity,
          gaplessPlayback: true,
        );
      },
    );
  }
}
