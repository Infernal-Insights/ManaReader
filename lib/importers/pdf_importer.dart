import 'dart:io';
import 'dart:ui' as ui;

import 'package:pdf_render/pdf_render.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/book_model.dart';
import 'importer.dart';

class PdfImporter extends Importer {
  @override
  Future<BookModel> import(String filePath) async {
    final doc = await PdfDocument.openFile(filePath);
    final baseName = p.basenameWithoutExtension(filePath);
    final destDir = await _createDestDir(baseName);
    final pages = <String>[];
    for (var i = 1; i <= doc.pageCount; i++) {
      final page = await doc.getPage(i);
      final img = await page.render(
          width: page.width.toInt(), height: page.height.toInt());
      final ui.Image image = await img.createImageIfNotAvailable();
      final bytes =
          (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      final imagePath = p.join(destDir.path, '${i.toString().padLeft(4, '0')}.png');
      final file = File(imagePath);
      await file.writeAsBytes(bytes);
      pages.add(imagePath);
    }
    await doc.dispose();
    return BookModel(
      title: baseName,
      path: destDir.path,
      language: 'unknown',
      pages: pages,
    );
  }

  Future<Directory> _createDestDir(String baseName) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'books', baseName));
    await dir.create(recursive: true);
    return dir;
  }
}
