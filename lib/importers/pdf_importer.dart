import 'dart:io';

import 'package:native_pdf_renderer/native_pdf_renderer.dart';
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
    for (var i = 1; i <= doc.pagesCount; i++) {
      final page = await doc.getPage(i);
      final img = await page.render(
        width: page.width,
        height: page.height,
        format: PdfPageImageFormat.png,
      );
      final imagePath =
          p.join(destDir.path, '${i.toString().padLeft(4, '0')}.png');
      final file = File(imagePath);
      await file.writeAsBytes(img!.bytes);
      pages.add(imagePath);
      await page.close();
    }
    await doc.close();
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
