import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mana_reader/importers/seven_zip_importer.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:archive/archive.dart';

import 'package:mana_reader/import/sync_service.dart';
import 'package:mana_reader/database/db_helper.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  final Directory tempDir = Directory.systemTemp.createTempSync(
    'mana_reader_test',
  );

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _FakePathProviderPlatform();

  const imgData =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=';

  setUp(() {
    PathProviderPlatform.instance = _FakePathProviderPlatform();
    processRun = (String exe, List<String> args) async {
      if (exe == 'which' || exe == 'where') {
        return ProcessResult(0, 0, '', '');
      }
      if (exe == '7z') {
        final archivePath = args[1];
        var destArg = args[2];
        if (destArg.startsWith('-o')) {
          destArg = destArg.substring(2);
        }
        final bytes = File(archivePath).readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        for (final f in archive) {
          if (f.isFile) {
            final out = File(p.join(destArg, f.name))
              ..createSync(recursive: true);
            out.writeAsBytesSync(f.content as List<int>);
          }
        }
        return ProcessResult(0, 0, '', '');
      }
      throw UnsupportedError(exe);
    };
  });

  test('syncDirectoryPath imports all archives', () async {
    final tmp = Directory.systemTemp.createTempSync();
    final img = base64Decode(imgData);

    // Create zip archive
    final zipArchive = Archive()
      ..addFile(ArchiveFile('a.png', img.length, img));
    final zipBytes = ZipEncoder().encode(zipArchive)!;
    File(p.join(tmp.path, 'a.cbz')).writeAsBytesSync(zipBytes);
    File(p.join(tmp.path, 'c.cb7')).writeAsBytesSync(zipBytes);
    File(p.join(tmp.path, 'd.7z')).writeAsBytesSync(zipBytes);

    final pdfData = base64Decode(
      'JVBERi0xLjEKMSAwIG9iajw8L1R5cGUvQ2F0YWxvZy9QYWdlcyAyIDAgUj4+ZW5kb2JqCjIgMCBvYmo8PC9UeXBlL1BhZ2VzL0tpZHNbMyAwIFJdL0NvdW50IDE+PmVuZG9iagozIDAgb2JqPDwvVHlwZS9QYWdlL1BhcmVudCAyIDAgUi9NZWRpYUJveFswIDAgNjEyIDc5Ml0+PmVuZG9iagp0cmFpbGVyPDwvUm9vdCAxIDAgUi9TaXplIDQ+PgolJUVPRg==',
    );
    File(p.join(tmp.path, 'e.pdf')).writeAsBytesSync(pdfData);

    final db = DbHelper();
    final success = await syncDirectoryPath(tmp.path, dbHelper: db);
    expect(success, isTrue);
    final books = await db.fetchBooks();
    expect(books, hasLength(4));
  });
}
