import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mana_reader/importers/seven_zip_importer.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:archive/archive.dart';
import 'package:native_pdf_renderer/native_pdf_renderer.dart';
import 'package:native_pdf_renderer/src/renderer/interfaces/platform.dart';

import 'package:mana_reader/import/sync_service.dart';
import 'package:mana_reader/database/db_helper.dart';

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
  final Directory tempDir = Directory.systemTemp.createTempSync('mana_reader_test');

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _FakePathProviderPlatform();

  const imgData = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=';

  setUp(() {
    PathProviderPlatform.instance = _FakePathProviderPlatform();
    PdfxPlatform.instance = _FakePdfxPlatform();
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
            final out = File(p.join(destArg, f.name))..createSync(recursive: true);
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
    final zipArchive = Archive()..addFile(ArchiveFile('a.png', img.length, img));
    final zipBytes = ZipEncoder().encode(zipArchive)!;
    File(p.join(tmp.path, 'a.cbz')).writeAsBytesSync(zipBytes);
    File(p.join(tmp.path, 'c.cb7')).writeAsBytesSync(zipBytes);
    File(p.join(tmp.path, 'd.7z')).writeAsBytesSync(zipBytes);

    final pdfData = base64Decode('JVBERi0xLjEKMSAwIG9iajw8L1R5cGUvQ2F0YWxvZy9QYWdlcyAyIDAgUj4+ZW5kb2JqCjIgMCBvYmo8PC9UeXBlL1BhZ2VzL0tpZHNbMyAwIFJdL0NvdW50IDE+PmVuZG9iagozIDAgb2JqPDwvVHlwZS9QYWdlL1BhcmVudCAyIDAgUi9NZWRpYUJveFswIDAgNjEyIDc5Ml0+PmVuZG9iagp0cmFpbGVyPDwvUm9vdCAxIDAgUi9TaXplIDQ+PgolJUVPRg==');
    File(p.join(tmp.path, 'e.pdf')).writeAsBytesSync(pdfData);

    final db = DbHelper();
    final success = await syncDirectoryPath(tmp.path, dbHelper: db);
    expect(success, isTrue);
    final books = await db.fetchBooks();
    expect(books, hasLength(4));
  });
}
