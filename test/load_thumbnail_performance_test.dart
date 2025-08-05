import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mana_reader/models/book_model.dart';
import 'package:mana_reader/screens/library_screen.dart';

void main() {
  test('loadThumbnail handles many non-image files quickly', () async {
    final dir = await Directory.systemTemp.createTemp('thumb_test');
    try {
      for (var i = 0; i < 1000; i++) {
        await File('${dir.path}/file$i.txt').writeAsString('x');
      }
      final image = File('${dir.path}/image.png');
      await image.writeAsBytes([0]);

      final book = BookModel(title: 'Test', path: dir.path, language: 'en');

      final sw = Stopwatch()..start();
      final thumb = await loadThumbnailForTest(book);
      sw.stop();

      expect(thumb, image.path);
      expect(sw.elapsed < const Duration(seconds: 1), isTrue,
          reason: 'Thumbnail lookup took too long');
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
