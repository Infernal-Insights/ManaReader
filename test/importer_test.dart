import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:archive/archive.dart';

import 'package:mana_reader/importers/importer_factory.dart';
import 'package:mana_reader/importers/folder_importer.dart';
import 'package:mana_reader/importers/zip_importer.dart';
import 'package:mana_reader/importers/seven_zip_importer.dart';
import 'package:mana_reader/importers/pdf_importer.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';
import 'package:native_pdf_renderer/src/renderer/interfaces/platform.dart';
import 'dart:typed_data';
import 'dart:async';

class _FakePdfxPlatform extends PdfxPlatform {
  @override
  Future<PdfDocument> openFile(String filePath, {String? password}) async =>
      _FakePdfDocument();

  @override
  Future<PdfDocument> openAsset(String name, {String? password}) async =>
      _FakePdfDocument();

  @override
  Future<PdfDocument> openData(FutureOr<Uint8List> data,
          {String? password}) async =>
      _FakePdfDocument();
}

class _FakePdfDocument extends PdfDocument {
  _FakePdfDocument()
      : super(sourceName: 'fake.pdf', id: '1', pagesCount: 1);

  @override
  Future<void> close() async {}

  @override
  Future<PdfPage> getPage(int pageNumber, {bool autoCloseAndroid = false}) async =>
      _FakePdfPage(this, pageNumber);

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => super.hashCode;
}

class _FakePdfPage extends PdfPage {
  _FakePdfPage(PdfDocument doc, int num)
      : super(
          document: doc,
          id: 'page$num',
          pageNumber: num,
          width: 1,
          height: 1,
          autoCloseAndroid: false,
        );

  @override
  Future<PdfPageImage?> render({
    required double width,
    required double height,
    PdfPageImageFormat format = PdfPageImageFormat.jpeg,
    String? backgroundColor,
    Rect? cropRect,
    int quality = 100,
    bool forPrint = false,
    bool removeTempFile = true,
  }) async {
    final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=');
    return _FakePdfPageImage(pageNumber, bytes, format, quality);
  }

  @override
  Future<PdfPageTexture> createTexture() => throw UnimplementedError();

  @override
  Future<void> close() async {}
}

class _FakePdfPageImage extends PdfPageImage {
  _FakePdfPageImage(
      int page, Uint8List bytes, PdfPageImageFormat format, int quality)
      : super(
          id: 'img$page',
          pageNumber: page,
          width: 1,
          height: 1,
          bytes: bytes,
          format: format,
          quality: quality,
        );

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => super.hashCode;
}

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

  group('ImporterFactory', () {
    test('selects importer based on extension', () {
      expect(ImporterFactory.fromPath('a.cbz'), isA<ZipImporter>());
      expect(ImporterFactory.fromPath('a.7z'), isA<SevenZipImporter>());
      expect(ImporterFactory.fromPath('dir'), isA<FolderImporter>());
    });
  });

  group('Importers', () {
    test('FolderImporter reads images', () async {
      final dir = Directory.systemTemp.createTempSync();
      final img = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=',
      );
      final imgPath = p.join(dir.path, 'a.png');
      File(imgPath).writeAsBytesSync(img);

      final importer = FolderImporter();
      final book = await importer.import(dir.path);
      expect(book.title, p.basename(dir.path));
      expect(book.pages, [imgPath]);
    });

    test('ZipImporter extracts images', () async {
      final tmp = Directory.systemTemp.createTempSync();
      final img = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=',
      );
      final archive = Archive()..addFile(ArchiveFile('b.png', img.length, img));
      final bytes = ZipEncoder().encode(archive)!;
      final zipPath = p.join(tmp.path, 'b.cbz');
      File(zipPath).writeAsBytesSync(bytes);

      final importer = ZipImporter();
      final book = await importer.import(zipPath);
      expect(book.pages.length, 1);
      expect(File(book.pages.first).existsSync(), isTrue);
    });

    test('ZipImporter ignores files with traversal paths', () async {
      final tmp = Directory.systemTemp.createTempSync();
      final img = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=',
      );
      final archive = Archive()
        ..addFile(ArchiveFile('c.png', img.length, img))
        ..addFile(ArchiveFile('../evil.png', img.length, img));
      final bytes = ZipEncoder().encode(archive)!;
      final zipPath = p.join(tmp.path, 'c.cbz');
      File(zipPath).writeAsBytesSync(bytes);

      final importer = ZipImporter();
      final book = await importer.import(zipPath);
      expect(book.pages.length, 1);
      expect(p.basename(book.pages.first), 'c.png');

      final docs = (PathProviderPlatform.instance as _FakePathProviderPlatform)
          .tempDir
          .path;
      final evilPath = p.join(docs, 'books', 'evil.png');
      expect(File(evilPath).existsSync(), isFalse);
    });

    test('SevenZipImporter extracts images', () async {
      final sevenScript = File('/usr/local/bin/7z');
      if (!sevenScript.existsSync()) {
        sevenScript.writeAsStringSync('''#!/usr/bin/env python3
import sys, zipfile, os
args=sys.argv[1:]
archive=args[1]
dest=args[2]
if dest.startswith("-o"):
    dest=dest[2:]
zipfile.ZipFile(archive).extractall(dest)
''');
        await Process.run('chmod', ['755', sevenScript.path]);
      }

      final tmp = Directory.systemTemp.createTempSync();
      final img = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=',
      );
      final archive = Archive()..addFile(ArchiveFile('d.png', img.length, img));
      final bytes = ZipEncoder().encode(archive)!;
      final sevenPath = p.join(tmp.path, 'd.cb7');
      File(sevenPath).writeAsBytesSync(bytes);

      final importer = SevenZipImporter();
      final book = await importer.import(sevenPath);
      expect(book.pages.length, 1);
      expect(File(book.pages.first).existsSync(), isTrue);
    });

    test('SevenZipImporter extracts images from .7z files', () async {
      final sevenScript = File('/usr/local/bin/7z');
      if (!sevenScript.existsSync()) {
        sevenScript.writeAsStringSync('''#!/usr/bin/env python3
import sys, zipfile, os
args=sys.argv[1:]
archive=args[1]
dest=args[2]
if dest.startswith("-o"):
    dest=dest[2:]
zipfile.ZipFile(archive).extractall(dest)
''');
        await Process.run('chmod', ['755', sevenScript.path]);
      }

      final tmp = Directory.systemTemp.createTempSync();
      final img = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=',
      );
      final archive = Archive()..addFile(ArchiveFile('e.png', img.length, img));
      final bytes = ZipEncoder().encode(archive)!;
      final sevenPath = p.join(tmp.path, 'e.7z');
      File(sevenPath).writeAsBytesSync(bytes);

      final importer = SevenZipImporter();
      final book = await importer.import(sevenPath);
      expect(book.pages.length, 1);
      expect(File(book.pages.first).existsSync(), isTrue);
    });

    test('PdfImporter renders pages', () async {
      PdfxPlatform.instance = _FakePdfxPlatform();
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
