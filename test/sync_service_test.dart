import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana_reader/importers/seven_zip_importer.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:archive/archive.dart';
import 'package:pdf_render_platform_interface/pdf_render.dart';
import 'package:pdf_render_platform_interface/pdf_render_platform_interface.dart';

import 'package:mana_reader/import/sync_service.dart';
import 'package:mana_reader/database/db_helper.dart';

class _FakePdfRenderPlatform extends PdfRenderPlatform {
  @override
  Future<PdfDocument?> openFile(String filePath) async => _FakePdfDocument();

  @override
  Future<PdfDocument?> openAsset(String name) async => _FakePdfDocument();

  @override
  Future<PdfDocument?> openData(Uint8List data) async => _FakePdfDocument();

  @override
  Future<PdfPageImageTexture> createTexture({required PdfDocument pdfDocument, required int pageNumber}) =>
      throw UnimplementedError();
}

class _FakePdfDocument extends PdfDocument {
  _FakePdfDocument()
      : super(
            sourceName: 'fake.pdf',
            pageCount: 1,
            verMajor: 1,
            verMinor: 7,
            isEncrypted: false,
            allowsCopying: true,
            allowsPrinting: true);

  @override
  Future<void> dispose() async {}

  @override
  Future<PdfPage> getPage(int pageNumber) async => _FakePdfPage(this, pageNumber);

  @override
  bool operator ==(dynamic other) => identical(this, other);

  @override
  int get hashCode => super.hashCode;
}

class _FakePdfPage extends PdfPage {
  _FakePdfPage(PdfDocument doc, int num)
      : super(document: doc, pageNumber: num, width: 1, height: 1);

  @override
  Future<PdfPageImage> render({
    int? x,
    int? y,
    int? width,
    int? height,
    double? fullWidth,
    double? fullHeight,
    bool? backgroundFill,
  }) async {
    return _FakePdfPageImage(pageNumber);
  }

  Future<void> close() async {}
}

class _FakePdfPageImage extends PdfPageImage {
  _FakePdfPageImage(int page)
      : _pixels = Uint8List.fromList(const [255, 0, 0, 255]),
        super(
            pageNumber: page,
            x: 0,
            y: 0,
            width: 1,
            height: 1,
            fullWidth: 1,
            fullHeight: 1,
            pageWidth: 1,
            pageHeight: 1);

  final Uint8List _pixels;
  ui.Image? _image;

  @override
  Uint8List get pixels => _pixels;

  @override
  Pointer<Uint8>? get buffer => null;

  @override
  void dispose() {}

  @override
  ui.Image? get imageIfAvailable => _image;

  @override
  Future<ui.Image> createImageIfNotAvailable() async {
    if (_image != null) return _image!;
    final comp = Completer<ui.Image>();
    ui.decodeImageFromPixels(
        _pixels, 1, 1, ui.PixelFormat.rgba8888, (img) => comp.complete(img));
    _image = await comp.future;
    return _image!;
  }

  @override
  Future<ui.Image> createImageDetached() async => await createImageIfNotAvailable();
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  final Directory tempDir = Directory.systemTemp.createTempSync('mana_reader_test');

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  PathProviderPlatform.instance = _FakePathProviderPlatform();

  const imgData = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=';

  setUp(() {
    PathProviderPlatform.instance = _FakePathProviderPlatform();
    PdfRenderPlatform.instance = _FakePdfRenderPlatform();
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

    const MethodChannel('com.lkrjangid.rar').setMockMethodCallHandler((call) async {
      if (call.method == 'extractRarFile') {
        final bytes = File(call.arguments['rarFilePath'] as String).readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        final dest = call.arguments['destinationPath'] as String;
        for (final f in archive) {
          if (f.isFile) {
            final out = File(p.join(dest, f.name))..createSync(recursive: true);
            out.writeAsBytesSync(f.content as List<int>);
          }
        }
        return {'success': true, 'message': 'ok'};
      }
      return null;
    });
  });

  test('syncDirectoryPath imports all archives', () async {
    final tmp = Directory.systemTemp.createTempSync();
    final img = base64Decode(imgData);

    // Create zip archive
    final zipArchive = Archive()..addFile(ArchiveFile('a.png', img.length, img));
    final zipBytes = ZipEncoder().encode(zipArchive)!;
    File(p.join(tmp.path, 'a.cbz')).writeAsBytesSync(zipBytes);
    File(p.join(tmp.path, 'b.cbr')).writeAsBytesSync(zipBytes);
    File(p.join(tmp.path, 'c.cb7')).writeAsBytesSync(zipBytes);
    File(p.join(tmp.path, 'd.7z')).writeAsBytesSync(zipBytes);

    final pdfData = base64Decode('JVBERi0xLjEKMSAwIG9iajw8L1R5cGUvQ2F0YWxvZy9QYWdlcyAyIDAgUj4+ZW5kb2JqCjIgMCBvYmo8PC9UeXBlL1BhZ2VzL0tpZHNbMyAwIFJdL0NvdW50IDE+PmVuZG9iagozIDAgb2JqPDwvVHlwZS9QYWdlL1BhcmVudCAyIDAgUi9NZWRpYUJveFswIDAgNjEyIDc5Ml0+PmVuZG9iagp0cmFpbGVyPDwvUm9vdCAxIDAgUi9TaXplIDQ+PgolJUVPRg==');
    File(p.join(tmp.path, 'e.pdf')).writeAsBytesSync(pdfData);

    final db = DbHelper();
    final success = await syncDirectoryPath(tmp.path, dbHelper: db);
    expect(success, isTrue);
    final books = await db.fetchBooks();
    expect(books, hasLength(5));
  });
}
