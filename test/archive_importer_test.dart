// Archive tests updated for new architecture.
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:mana_reader/core/archive/cbz_archive.dart';
import 'package:mana_reader/core/archive/image_folder_archive.dart';
import 'package:mana_reader/core/archive/archive_factory.dart';

// Minimal 1x1 white PNG
final _pngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // signature
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x02,
  0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE,
  0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, // IDAT
  0x08, 0xD7, 0x63, 0xF8, 0xFF, 0xFF, 0x3F, 0x00, 0x05, 0xFE,
  0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84,
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82, // IEND
]);

Archive _makeZipWithImages(List<String> names) {
  final archive = Archive();
  for (final name in names) {
    final f = ArchiveFile(name, _pngBytes.length, _pngBytes);
    archive.addFile(f);
  }
  return archive;
}

void main() {
  group('CbzArchive', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('cbz_test');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('reads page count from zip', () async {
      final archive = _makeZipWithImages(['001.png', '002.png', '003.png']);
      final bytes = ZipEncoder().encode(archive)!;
      final path = p.join(tempDir.path, 'test.cbz');
      File(path).writeAsBytesSync(bytes);

      final cbz = CbzArchive(path);
      expect(await cbz.pageCount, 3);
    });

    test('getPage returns bytes', () async {
      final archive = _makeZipWithImages(['001.png']);
      final bytes = ZipEncoder().encode(archive)!;
      final path = p.join(tempDir.path, 'single.cbz');
      File(path).writeAsBytesSync(bytes);

      final cbz = CbzArchive(path);
      final page = await cbz.getPage(0);
      expect(page.index, 0);
      expect(page.bytes, isNotEmpty);
    });

    test('metadata title is filename without extension', () async {
      final archive = _makeZipWithImages(['001.png']);
      final bytes = ZipEncoder().encode(archive)!;
      final path = p.join(tempDir.path, 'MyComicTitle.cbz');
      File(path).writeAsBytesSync(bytes);

      final cbz = CbzArchive(path);
      expect(cbz.metadata.title, 'MyComicTitle');
    });
  });

  group('ImageFolderArchive', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('imgfolder_test');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('counts image files', () async {
      File(p.join(tempDir.path, 'a.png')).writeAsBytesSync(_pngBytes);
      File(p.join(tempDir.path, 'b.jpg')).writeAsBytesSync(_pngBytes);
      File(p.join(tempDir.path, 'readme.txt')).writeAsStringSync('ignore');

      final ia = ImageFolderArchive(tempDir.path);
      expect(await ia.pageCount, 2);
    });
  });

  group('ArchiveFactory', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('factory_test');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('creates CbzArchive for .cbz', () {
      final path = p.join(tempDir.path, 'comic.cbz');
      File(path).writeAsBytesSync(const []);
      final archive = ArchiveFactory.fromPath(path);
      expect(archive, isA<CbzArchive>());
    });

    test('creates ImageFolderArchive for directory', () {
      final archive = ArchiveFactory.fromPath(tempDir.path);
      expect(archive, isA<ImageFolderArchive>());
    });

    test('isSupported returns false for unknown ext', () {
      final path = p.join(tempDir.path, 'file.rar');
      File(path).writeAsBytesSync(const []);
      expect(ArchiveFactory.isSupported(path), isFalse);
    });
  });
}
