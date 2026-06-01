import 'dart:typed_data';

/// Metadata extracted from an archive (filename or ComicInfo.xml).
class ArchiveMetadata {
  final String title;
  final String? author;
  final String? series;
  final int? volume;
  final int? chapter;
  final String? language;
  final List<String> tags;

  const ArchiveMetadata({
    required this.title,
    this.author,
    this.series,
    this.volume,
    this.chapter,
    this.language,
    this.tags = const [],
  });
}

/// A single decoded page image.
class PageImage {
  final int index;
  final Uint8List bytes;
  final int width;
  final int height;

  const PageImage({
    required this.index,
    required this.bytes,
    required this.width,
    required this.height,
  });
}

/// Format-agnostic reader contract.
abstract class ComicArchive {
  Future<int> get pageCount;
  Future<PageImage> getPage(int index);
  ArchiveMetadata get metadata;
  Future<void> dispose();
}
