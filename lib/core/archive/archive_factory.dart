import 'dart:io';
import 'package:path/path.dart' as p;

import 'comic_archive.dart';
import 'cbz_archive.dart';
import 'pdf_archive.dart';
import 'image_folder_archive.dart';

/// Creates the correct [ComicArchive] implementation based on file extension or type.
class ArchiveFactory {
  ArchiveFactory._();

  static ComicArchive fromPath(String path) {
    final stat = FileStat.statSync(path);
    if (stat.type == FileSystemEntityType.directory) {
      return ImageFolderArchive(path);
    }
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.cbz':
      case '.zip':
        return CbzArchive(path);
      case '.pdf':
        return PdfArchive(path);
      default:
        throw UnsupportedError('Unsupported archive format: $ext');
    }
  }

  static bool isSupported(String path) {
    final stat = FileStat.statSync(path);
    if (stat.type == FileSystemEntityType.directory) return true;
    final ext = p.extension(path).toLowerCase();
    return const {'.cbz', '.zip', '.pdf'}.contains(ext);
  }
}
