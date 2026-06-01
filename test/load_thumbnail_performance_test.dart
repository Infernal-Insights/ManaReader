// Performance test updated for new architecture.
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:mana_reader/core/archive/cbz_archive.dart';

// Minimal valid PNG bytes
final _png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE,
  0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54,
  0x08, 0xD7, 0x63, 0xF8, 0xFF, 0xFF, 0x3F, 0x00,
  0x05, 0xFE, 0x02, 0xFE, 0xA7, 0x35, 0x81, 0x84,
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44,
  0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  test('CbzArchive page access performance', () async {
    final dir = Directory.systemTemp.createTempSync('perf_test');
    try {
      // Create a zip with 50 pages
      final archive = Archive();
      for (var i = 0; i < 50; i++) {
        final name = '${i.toString().padLeft(3, '0')}.png';
        archive.addFile(ArchiveFile(name, _png.length, _png));
      }
      final bytes = ZipEncoder().encode(archive)!;
      final path = p.join(dir.path, 'big.cbz');
      File(path).writeAsBytesSync(bytes);

      final cbz = CbzArchive(path);
      final stopwatch = Stopwatch()..start();

      expect(await cbz.pageCount, 50);
      for (var i = 0; i < 50; i++) {
        final page = await cbz.getPage(i);
        expect(page.bytes, isNotEmpty);
      }

      stopwatch.stop();
      // Should complete in under 5 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
