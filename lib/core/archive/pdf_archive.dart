import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

import 'comic_archive.dart';

/// PDF implementation of [ComicArchive] using the pdfrx package.
class PdfArchive implements ComicArchive {
  final String _filePath;
  PdfDocument? _doc;
  late ArchiveMetadata _metadata;

  PdfArchive(this._filePath);

  Future<void> _init() async {
    if (_doc != null) return;
    _doc = await PdfDocument.openFile(_filePath);
    _metadata = ArchiveMetadata(title: p.basenameWithoutExtension(_filePath));
  }

  @override
  Future<int> get pageCount async {
    await _init();
    return _doc!.pages.length;
  }

  @override
  Future<PageImage> getPage(int index) async {
    await _init();
    final doc = _doc!;
    if (index < 0 || index >= doc.pages.length) {
      throw RangeError('Page index $index out of range');
    }
    final page = doc.pages[index];
    final width = (page.width * 2).toInt();
    final height = (page.height * 2).toInt();
    final image = await page.render(
      fullWidth: width.toDouble(),
      fullHeight: height.toDouble(),
    );
    // image.pixels is RGBA bytes
    return PageImage(
      index: index,
      bytes: Uint8List.fromList(image!.pixels),
      width: width,
      height: height,
    );
  }

  @override
  ArchiveMetadata get metadata => _metadata;

  @override
  Future<void> dispose() async {
    await _doc?.dispose();
    _doc = null;
  }
}
