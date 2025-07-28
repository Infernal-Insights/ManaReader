import 'dart:async';

class Metadata {
  final String title;
  final String language;
  final List<String> tags;

  Metadata({required this.title, required this.language, this.tags = const []});
}

abstract class MetadataProvider {
  String get name;

  /// Return metadata for the given search query or null if not found.
  Future<Metadata?> search(String query);
}
