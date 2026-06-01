import 'dart:io';

/// A single item surfaced by a [ContentSource].
class SourceItem {
  final String id;
  final String title;
  final String? remoteId; // provider-specific identifier
  final String? thumbnailUrl;
  final int? fileSizeBytes;
  final DateTime? modifiedAt;

  const SourceItem({
    required this.id,
    required this.title,
    this.remoteId,
    this.thumbnailUrl,
    this.fileSizeBytes,
    this.modifiedAt,
  });
}

/// Source-agnostic library contract.
abstract class ContentSource {
  String get id;
  String get displayName;
  bool get supportsWatching;

  Future<List<SourceItem>> listItems();
  Future<File> fetchFile(String itemId);
  Future<void> dispose();
}
