import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'comic_archive.dart';

/// Image-folder implementation of [ComicArchive].
class ImageFolderArchive implements ComicArchive {
  final String _dirPath;
  List<File>? _pages;
  late ArchiveMetadata _metadata;

  ImageFolderArchive(this._dirPath);

  Future<void> _init() async {
    if (_pages != null) return;
    final dir = Directory(_dirPath);
    final entries = await dir.list().toList();
    _pages = entries
        .whereType<File>()
        .where((f) => _isImage(f.path))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    _metadata = ArchiveMetadata(title: p.basename(_dirPath));
  }

  @override
  Future<int> get pageCount async {
    await _init();
    return _pages!.length;
  }

  @override
  Future<PageImage> getPage(int index) async {
    await _init();
    final pages = _pages!;
    if (index < 0 || index >= pages.length) {
      throw RangeError('Page index $index out of range');
    }
    final bytes = await pages[index].readAsBytes();
    return PageImage(index: index, bytes: bytes, width: 0, height: 0);
  }

  @override
  ArchiveMetadata get metadata => _metadata;

  @override
  Future<void> dispose() async {}

  static bool _isImage(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }
}
