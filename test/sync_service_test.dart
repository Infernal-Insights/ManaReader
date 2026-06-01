// Sync engine tests updated for new architecture.
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:mana_reader/core/db/database.dart';
import 'package:mana_reader/core/source/content_source.dart';
import 'package:mana_reader/core/source/local_folder_source.dart';
import 'package:mana_reader/core/sync/sync_engine.dart';

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncEngine', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('sync_test');
    });

    tearDown(() => tempDir.deleteSync(recursive: true));

    test('sync adds new items to manifest', () async {
      // Create a fake .cbz file
      final file = File(p.join(tempDir.path, 'comic.cbz'));
      file.writeAsBytesSync([]);

      final db = _makeDb();
      final source = LocalFolderSource(id: 'src1', folderPath: tempDir.path);
      final engine = SyncEngine(db);

      final result = await engine.sync(source);
      expect(result.added, greaterThanOrEqualTo(1));

      final items = await db.manifestDao.bySource('src1');
      expect(items, isNotEmpty);

      await db.close();
    });

    test('deleteItem sets userDeleted tombstone', () async {
      final db = _makeDb();
      await db.manifestDao.upsert(SyncManifestCompanion(
        id: const Value('item1'),
        sourceId: const Value('src1'),
        remotePath: const Value('/r/comic.cbz'),
        cacheState: const Value('remote'),
      ));

      final engine = SyncEngine(db);
      await engine.deleteItem('item1');

      final row = await db.manifestDao.getById('item1');
      expect(row!.userDeleted, isTrue);

      await db.close();
    });

    test('deleted items are not re-synced', () async {
      final file = File(p.join(tempDir.path, 'deleted.cbz'));
      file.writeAsBytesSync([]);

      final db = _makeDb();
      final source = LocalFolderSource(id: 'src1', folderPath: tempDir.path);
      final engine = SyncEngine(db);

      // First sync - item appears
      await engine.sync(source);
      // Mark as user-deleted
      await engine.deleteItem(file.path);

      // Second sync - item should not be re-added
      final result2 = await engine.sync(source);
      expect(result2.added, 0);

      await db.close();
    });
  });
}
