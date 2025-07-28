import '../database/db_helper.dart';
import '../importers/importer_factory.dart';
import '../models/book_model.dart';
import '../metadata/metadata_service.dart';

/// High level helper that imports a book path and resolves metadata.
class Importer {
  Importer({DbHelper? dbHelper, MetadataService? metadata})
      : _dbHelper = dbHelper ?? DbHelper.instance,
        _metadata = metadata ?? MetadataService();

  final DbHelper _dbHelper;
  final MetadataService _metadata;

  Future<int> importPath(String path) async {
    final inner = ImporterFactory.fromPath(path);
    final book = await inner.import(path);

    final meta = await _metadata.resolve(book.title);
    final merged = BookModel(
      title: meta?.title ?? book.title,
      path: book.path,
      author: meta?.author ?? book.author,
      language: meta?.language ?? book.language,
      tags: meta?.tags ?? book.tags,
      pages: book.pages,
    );

    return _dbHelper.insertBook(merged);
  }
}

