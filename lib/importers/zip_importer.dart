import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/book_model.dart';
import 'importer.dart';

class ZipImporter extends Importer {
  @override
  Future<BookModel> import(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final baseName = p.basenameWithoutExtension(filePath);
    final destDir = await _createDestDir(baseName);
    final pages = <String>[];
    for (final file in archive) {
      if (file.isFile) {
        final outPath = p.join(destDir.path, file.name);
        File(outPath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(file.content as List<int>);
        if (_isImage(file.name)) {
          pages.add(outPath);
        }
      }
    }
    pages.sort();
    return BookModel(
      title: baseName,
      path: destDir.path,
      language: 'unknown',
      pages: pages,
    );
  }

  bool _isImage(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif');
  }

  Future<Directory> _createDestDir(String baseName) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'books', baseName));
    await dir.create(recursive: true);
    return dir;
  }
}
