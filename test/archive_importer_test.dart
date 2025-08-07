import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:archive/archive.dart';

import 'package:mana_reader/importers/seven_zip_importer.dart';
import 'package:mana_reader/importers/pdf_importer.dart';

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

  group('Archive importers', () {
    test('SevenZipImporter extracts images using mocked Process.run', () async {
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

      final tmp = Directory.systemTemp.createTempSync();
      final img = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAA C0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=',
      );
      final archive = Archive()..addFile(ArchiveFile('b.png', img.length, img));
      final bytes = ZipEncoder().encode(archive)!;
      final sevenPath = p.join(tmp.path, 't.cb7');
      File(sevenPath).writeAsBytesSync(bytes);

      final importer = SevenZipImporter();
      final book = await importer.import(sevenPath);
      expect(book.pages.length, 1);
      expect(File(book.pages.first).existsSync(), isTrue);
    });

    test(
      'SevenZipImporter extracts images from .7z using mocked Process.run',
      () async {
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

        final tmp = Directory.systemTemp.createTempSync();
        final img = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAA C0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=',
        );
        final archive = Archive()
          ..addFile(ArchiveFile('c.png', img.length, img));
        final bytes = ZipEncoder().encode(archive)!;
        final sevenPath = p.join(tmp.path, 't.7z');
        File(sevenPath).writeAsBytesSync(bytes);

        final importer = SevenZipImporter();
        final book = await importer.import(sevenPath);
        expect(book.pages.length, 1);
        expect(File(book.pages.first).existsSync(), isTrue);
      },
    );

    test('PdfImporter renders pages from small PDF', () async {
      final tmp = Directory.systemTemp.createTempSync();
      final pdfData = base64Decode(
        'JVBERi0xLjEKMSAwIG9iajw8L1R5cGUvQ2F0YWxvZy9QYWdlcyAyIDAgUj4+ZW5kb2JqCjIgMCBvYmo8PC9UeXBlL1BhZ2VzL0tpZHNbMyAwIFJdL0NvdW50IDE+PmVuZG9iagozIDAgb2JqPDwvVHlwZS9QYWdlL1BhcmVudCAyIDAgUi9NZWRpYUJveFswIDAgNjEyIDc5Ml0+PmVuZG9iagp0cmFpbGVyPDwvUm9vdCAxIDAgUi9TaXplIDQ+PgolJUVPRg==',
      );
      final pdfPath = p.join(tmp.path, 'a.pdf');
      File(pdfPath).writeAsBytesSync(pdfData);

      final importer = PdfImporter();
      final book = await importer.import(pdfPath);
      expect(book.pages.length, 1);
      expect(File(book.pages.first).existsSync(), isTrue);
    });
  });
}
