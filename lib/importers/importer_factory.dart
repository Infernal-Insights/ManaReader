import 'importer.dart';
import 'zip_importer.dart';
import 'rar_importer.dart';
import 'seven_zip_importer.dart';

class ImporterFactory {
  static Importer fromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.cbz') || lower.endsWith('.zip')) {
      return ZipImporter();
    } else if (lower.endsWith('.cbr') || lower.endsWith('.rar')) {
      return RarImporter();
    } else if (lower.endsWith('.cb7') || lower.endsWith('.7z')) {
      return SevenZipImporter();
    } else {
      throw UnsupportedError('Unsupported archive type');
    }
  }
}
