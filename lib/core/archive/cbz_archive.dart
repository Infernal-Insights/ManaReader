import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'comic_archive.dart';
import '../comicinfo/comic_info_parser.dart';

/// CBZ (ZIP) implementation of [ComicArchive].
/// Pages are decoded on-demand from the in-memory archive.
class CbzArchive implements ComicArchive {
  final String _filePath;
  late Archive _archive;
  late List<ArchiveFile> _imageFiles;
  ArchiveMetadata _metadata = const ArchiveMetadata(title: '');
  bool _initialized = false;

  CbzArchive(this._filePath);

  Future<void> _init() async {
    if (_initialized) return;
    final bytes = await File(_filePath).readAsBytes();
    _archive = ZipDecoder().decodeBytes(bytes);

    // Collect image files, sorted by name
    _imageFiles = _archive.files
        .where((f) => f.isFile && _isImage(f.name))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    // Try to parse ComicInfo.xml
    final comicInfoFile = _archive.files.firstWhere(
      (f) => f.name.toLowerCase() == 'comicinfo.xml',
      orElse: () => ArchiveFile('', 0, <int>[]),
    );

    ArchiveMetadata? parsedMeta;
    if (comicInfoFile.name.isNotEmpty) {
      try {
        final xml = String.fromCharCodes(comicInfoFile.content as List<int>);
        parsedMeta = ComicInfoParser.parse(xml);
      } catch (e) {
        debugPrint('ComicInfo.xml parse error: $e');
      }
    }

    _metadata = parsedMeta ??
        ArchiveMetadata(title: p.basenameWithoutExtension(_filePath));
    _initialized = true;
  }

  @override
  Future<int> get pageCount async {
    await _init();
    return _imageFiles.length;
  }

  @override
  Future<PageImage> getPage(int index) async {
    await _init();
    if (index < 0 || index >= _imageFiles.length) {
      throw RangeError('Page index $index out of range');
    }
    final bytes = Uint8List.fromList(_imageFiles[index].content as List<int>);
    // We don't decode dimensions here to keep it lightweight; consumers can
    // decode if needed.
    return PageImage(index: index, bytes: bytes, width: 0, height: 0);
  }

  @override
  ArchiveMetadata get metadata => _metadata;

  @override
  Future<void> dispose() async {
    // Archive held in memory; GC will handle it.
  }

  static bool _isImage(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }
}
