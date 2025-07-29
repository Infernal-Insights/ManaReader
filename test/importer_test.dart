import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:archive/archive.dart';

import 'package:mana_reader/importers/importer_factory.dart';
import 'package:mana_reader/importers/folder_importer.dart';
import 'package:mana_reader/importers/zip_importer.dart';


class _FakePathProviderPlatform extends PathProviderPlatform {
  final Directory tempDir = Directory.systemTemp.createTempSync('mana_reader_test');

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _FakePathProviderPlatform();

  group('ImporterFactory', () {
    test('selects importer based on extension', () {
      expect(ImporterFactory.fromPath('a.cbz'), isA<ZipImporter>());
      expect(ImporterFactory.fromPath('dir'), isA<FolderImporter>());
    });
  });

  group('Importers', () {
    test('FolderImporter reads images', () async {
      final dir = Directory.systemTemp.createTempSync();
      final img = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=');
      final imgPath = p.join(dir.path, 'a.png');
      File(imgPath).writeAsBytesSync(img);

      final importer = FolderImporter();
      final book = await importer.import(dir.path);
      expect(book.title, p.basename(dir.path));
      expect(book.pages, [imgPath]);
    });

    test('ZipImporter extracts images', () async {
      final tmp = Directory.systemTemp.createTempSync();
      final img = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=');
      final archive = Archive()
        ..addFile(ArchiveFile('b.png', img.length, img));
      final bytes = ZipEncoder().encode(archive)!;
      final zipPath = p.join(tmp.path, 'b.cbz');
      File(zipPath).writeAsBytesSync(bytes);

      final importer = ZipImporter();
      final book = await importer.import(zipPath);
      expect(book.pages.length, 1);
      expect(File(book.pages.first).existsSync(), isTrue);
    });
  });
}
