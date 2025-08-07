import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/db_helper.dart';
import 'importer.dart';

/// Scans [dirPath] for supported archives and imports any that are not already
/// present in the database. Returns `true` if all archives were imported
/// successfully, or `false` if some failed.
Future<bool> syncDirectoryPath(String dirPath, {DbHelper? dbHelper}) async {
  final directory = Directory(dirPath);
  if (!await directory.exists()) return true;

  final db = dbHelper ?? DbHelper.instance;
  final books = await db.fetchBooks();
  final existingPaths = books.map((b) => b.path).toSet();

  final docs = await getApplicationDocumentsDirectory();
  final importer = Importer(dbHelper: db);

  var allSuccess = true;

  await for (final entity in directory.list(recursive: true)) {
    if (entity is! File) continue;
    final lower = entity.path.toLowerCase();
    if (!(lower.endsWith('.cbz') ||
        lower.endsWith('.cb7') ||
        lower.endsWith('.7z') ||
        lower.endsWith('.pdf'))) {
      continue;
    }
    final baseName = p.basenameWithoutExtension(entity.path);
    final destPath = p.join(docs.path, 'books', baseName);
    if (existingPaths.contains(destPath)) continue;
    try {
      await importer.importPath(entity.path);
      existingPaths.add(destPath);
    } catch (e, st) {
      debugPrint('Failed to import ${entity.path}: $e');
      debugPrint('$st');
      allSuccess = false;
    }
  }
  return allSuccess;
}
