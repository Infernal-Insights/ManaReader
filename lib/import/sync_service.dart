import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/db_helper.dart';
import 'importer.dart';

/// Scans [dirPath] for supported archives and imports any that are not already present in the database.
Future<void> syncDirectoryPath(String dirPath, {DbHelper? dbHelper}) async {
  final directory = Directory(dirPath);
  if (!await directory.exists()) return;

  final db = dbHelper ?? DbHelper.instance;
  final books = await db.fetchBooks();
  final existingPaths = books.map((b) => b.path).toSet();

  final docs = await getApplicationDocumentsDirectory();
  final importer = Importer(dbHelper: db);

  await for (final entity in directory.list(recursive: true)) {
    if (entity is! File) continue;
    final lower = entity.path.toLowerCase();
    if (!(lower.endsWith('.cbz') ||
        lower.endsWith('.cbr') ||
        lower.endsWith('.cb7') ||
        lower.endsWith('.pdf'))) {
      continue;
    }
    final baseName = p.basenameWithoutExtension(entity.path);
    final destPath = p.join(docs.path, 'books', baseName);
    if (existingPaths.contains(destPath)) continue;
    try {
      await importer.importPath(entity.path);
      existingPaths.add(destPath);
    } catch (_) {
      // Ignore individual import failures
    }
  }
}
