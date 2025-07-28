import '../database/db_helper.dart';
import '../metadata/metadata_service.dart';

/// High level helper that imports a book path and resolves metadata.
class Importer {
  Importer({DbHelper? dbHelper, MetadataService? metadata})
      : _dbHelper = dbHelper ?? DbHelper.instance,
        _metadata = metadata ?? MetadataService();

  final DbHelper _dbHelper;
  final MetadataService _metadata;

  Future<int> importPath(String path) {
    return _dbHelper.importBook(path, _metadata);
  }
}

