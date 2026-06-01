import 'dart:io';
import 'package:path/path.dart' as p;

import 'content_source.dart';
import '../archive/archive_factory.dart';

/// Local filesystem folder implementation of [ContentSource].
class LocalFolderSource implements ContentSource {
  @override
  final String id;

  @override
  final String displayName;

  final String folderPath;

  @override
  final bool supportsWatching;

  LocalFolderSource({
    required this.id,
    required this.folderPath,
    String? displayName,
    this.supportsWatching = false,
  }) : displayName = displayName ?? p.basename(folderPath);

  @override
  Future<List<SourceItem>> listItems() async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return [];

    final items = <SourceItem>[];
    await for (final entity in dir.list(followLinks: true)) {
      if (entity is File && ArchiveFactory.isSupported(entity.path)) {
        final stat = await entity.stat();
        items.add(SourceItem(
          id: entity.path,
          title: p.basenameWithoutExtension(entity.path),
          fileSizeBytes: stat.size,
          modifiedAt: stat.modified,
        ));
      } else if (entity is Directory) {
        // Check if the directory contains images (image folder archive)
        final hasImages = await _directoryHasImages(entity);
        if (hasImages) {
          final stat = await entity.stat();
          items.add(SourceItem(
            id: entity.path,
            title: p.basename(entity.path),
            modifiedAt: stat.modified,
          ));
        }
      }
    }

    items.sort((a, b) => a.title.compareTo(b.title));
    return items;
  }

  @override
  Future<File> fetchFile(String itemId) async {
    // For local sources, itemId IS the path
    final f = File(itemId);
    if (await f.exists()) return f;
    throw FileSystemException('File not found: $itemId');
  }

  @override
  Future<void> dispose() async {}

  static Future<bool> _directoryHasImages(Directory dir) async {
    await for (final entity in dir.list()) {
      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (const {'.jpg', '.jpeg', '.png', '.webp', '.gif'}.contains(ext)) {
          return true;
        }
      }
    }
    return false;
  }
}
