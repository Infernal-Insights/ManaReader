import 'dart:io';

import 'importer.dart';
import 'zip_importer.dart';
import 'seven_zip_importer.dart';
import 'pdf_importer.dart';
import 'folder_importer.dart';

class ImporterFactory {
  static Importer fromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.cbz') || lower.endsWith('.zip')) {
      return ZipImporter();
    } else if (lower.endsWith('.cb7') || lower.endsWith('.7z')) {
      return SevenZipImporter();
    } else if (lower.endsWith('.pdf')) {
      return PdfImporter();
    } else if (lower.endsWith('.cbr') || lower.endsWith('.rar')) {
      throw UnsupportedError('RAR archives are not supported');
    } else if (FileSystemEntity.isDirectorySync(path)) {
      return FolderImporter();
    } else {
      throw UnsupportedError('Unsupported archive type');
    }
  }
}
