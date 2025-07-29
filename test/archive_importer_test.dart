import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ffi';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:archive/archive.dart';
import 'package:pdf_render/pdf_render.dart';

import 'package:mana_reader/importers/rar_importer.dart';
import 'package:mana_reader/importers/seven_zip_importer.dart';
import 'package:mana_reader/importers/pdf_importer.dart';

class _FakePdfRenderPlatform extends PdfRenderPlatform {
  @override
  Future<PdfDocument> openFile(String filePath) async => _FakePdfDocument();

  @override
  Future<PdfDocument> openAsset(String name) async => _FakePdfDocument();

  @override
  Future<PdfDocument> openData(Uint8List data) async => _FakePdfDocument();

  @override
  Future<PdfPageImageTexture> createTexture({required FutureOr<PdfDocument> pdfDocument, required int pageNumber}) =>
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
    int x = 0,
    int y = 0,
    int? width,
    int? height,
    double? fullWidth,
    double? fullHeight,
    bool backgroundFill = true,
    bool allowAntialiasingIOS = false,
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
    ui.decodeImageFromPixels(_pixels, 1, 1, ui.PixelFormat.rgba8888, (img) => comp.complete(img));
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
  PathProviderPlatform.instance = _FakePathProviderPlatform();

  group('Archive importers', () {
    test('RarImporter extracts images from archive', () async {
      const channel = MethodChannel('com.lkrjangid.rar');
      channel.setMockMethodCallHandler((call) async {
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

      final tmp = Directory.systemTemp.createTempSync();
      final img = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAA C0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=');
      final archive = Archive()..addFile(ArchiveFile('a.png', img.length, img));
      final bytes = ZipEncoder().encode(archive)!;
      final rarPath = p.join(tmp.path, 't.cbr');
      File(rarPath).writeAsBytesSync(bytes);

      final importer = RarImporter();
      final book = await importer.import(rarPath);
      expect(book.pages.length, 1);
      expect(File(book.pages.first).existsSync(), isTrue);
    });

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
              final out = File(p.join(destArg, f.name))..createSync(recursive: true);
              out.writeAsBytesSync(f.content as List<int>);
            }
          }
          return ProcessResult(0, 0, '', '');
        }
        throw UnsupportedError(exe);
      };

      final tmp = Directory.systemTemp.createTempSync();
      final img = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAA C0lEQVR42mP8Xw8AAiMB7g6lbYkAAAAASUVORK5CYII=');
      final archive = Archive()..addFile(ArchiveFile('b.png', img.length, img));
      final bytes = ZipEncoder().encode(archive)!;
      final sevenPath = p.join(tmp.path, 't.cb7');
      File(sevenPath).writeAsBytesSync(bytes);

      final importer = SevenZipImporter();
      final book = await importer.import(sevenPath);
      expect(book.pages.length, 1);
      expect(File(book.pages.first).existsSync(), isTrue);
    });

    test('PdfImporter renders pages from small PDF', () async {
      PdfRenderPlatform.instance = _FakePdfRenderPlatform();
      final tmp = Directory.systemTemp.createTempSync();
      final pdfData = base64Decode('JVBERi0xLjEKMSAwIG9iajw8L1R5cGUvQ2F0YWxvZy9QYWdlcyAyIDAgUj4+ZW5kb2JqCjIgMCBvYmo8PC9UeXBlL1BhZ2VzL0tpZHNbMyAwIFJdL0NvdW50IDE+PmVuZG9iagozIDAgb2JqPDwvVHlwZS9QYWdlL1BhcmVudCAyIDAgUi9NZWRpYUJveFswIDAgNjEyIDc5Ml0+PmVuZG9iagp0cmFpbGVyPDwvUm9vdCAxIDAgUi9TaXplIDQ+PgolJUVPRg==');
      final pdfPath = p.join(tmp.path, 'a.pdf');
      File(pdfPath).writeAsBytesSync(pdfData);

      final importer = PdfImporter();
      final book = await importer.import(pdfPath);
      expect(book.pages.length, 1);
      expect(File(book.pages.first).existsSync(), isTrue);
    });
  });
}

