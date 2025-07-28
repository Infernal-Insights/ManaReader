import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/book_model.dart';
import 'importer.dart';

class FolderImporter extends Importer {
  @override
  Future<BookModel> import(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw Exception('Directory not found');
    }
    final pages = dir
        .listSync()
        .whereType<File>()
        .where((f) => _isImage(f.path))
        .map((f) => f.path)
        .toList()
      ..sort();
    return BookModel(
      title: p.basename(path),
      path: dir.path,
      language: 'unknown',
      pages: pages,
    );
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif');
  }
}
