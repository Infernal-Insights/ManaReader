import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/book_model.dart';
import 'importer.dart';

class SevenZipImporter extends Importer {
  @override
  Future<BookModel> import(String filePath) async {
    await _verifySevenZip();
    final baseName = p.basenameWithoutExtension(filePath);
    final destDir = await _createDestDir(baseName);
    final result = await Process.run('7z', ['x', filePath, '-o${destDir.path}']);
    if (result.exitCode != 0) {
      throw Exception(result.stderr);
    }
    final pages = _collectPages(destDir.path);
    return BookModel(
      title: baseName,
      path: destDir.path,
      language: 'unknown',
      pages: pages,
    );
  }

  Future<Directory> _createDestDir(String baseName) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'books', baseName));
    await dir.create(recursive: true);
    return dir;
  }

  List<String> _collectPages(String dirPath) {
    final dir = Directory(dirPath);
    final pages = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => _isImage(f.path))
        .map((f) => f.path)
        .toList()
      ..sort();
    return pages;
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif');
  }

  Future<void> _verifySevenZip() async {
    final cmd = Platform.isWindows ? 'where' : 'which';
    try {
      final result = await Process.run(cmd, ['7z']);
      if (result.exitCode != 0) {
        throw const ProcessException('7z', []);
      }
    } on ProcessException {
      throw Exception(
          '7-Zip executable not found. Please install 7-Zip and ensure "7z" is in your PATH.');
    }
  }
}
