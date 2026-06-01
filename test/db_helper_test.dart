// Database tests updated for new drift-based architecture.
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mana_reader/core/db/database.dart';

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SeriesDao', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('insert and fetch series', () async {
      await db.seriesDao.upsert(SeriesCompanion(
        id: const Value('s1'),
        title: const Value('My Series'),
        sortKey: const Value('my series'),
      ));
      final all = await db.seriesDao.allSeries();
      expect(all, hasLength(1));
      expect(all.first.title, 'My Series');
    });

    test('search by title', () async {
      await db.seriesDao.upsert(SeriesCompanion(
        id: const Value('s1'),
        title: const Value('Berserk'),
        sortKey: const Value('berserk'),
      ));
      await db.seriesDao.upsert(SeriesCompanion(
        id: const Value('s2'),
        title: const Value('Naruto'),
        sortKey: const Value('naruto'),
      ));
      final results = await db.seriesDao.search('ber');
      expect(results.map((s) => s.title), contains('Berserk'));
      expect(results.map((s) => s.title), isNot(contains('Naruto')));
    });

    test('delete series', () async {
      await db.seriesDao.upsert(SeriesCompanion(
        id: const Value('del'),
        title: const Value('To Delete'),
        sortKey: const Value('to delete'),
      ));
      await db.seriesDao.deleteById('del');
      final all = await db.seriesDao.allSeries();
      expect(all, isEmpty);
    });
  });

  group('ProgressDao', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('upsert and fetch progress', () async {
      await db.progressDao.upsert(ReadingProgressCompanion(
        seriesId: const Value('s1'),
        currentItemId: const Value('i1'),
        pageIndex: const Value(5),
        updatedAt: Value(DateTime(2024)),
      ));
      final p = await db.progressDao.getProgress('s1');
      expect(p, isNotNull);
      expect(p!.pageIndex, 5);
    });

    test('recentlyRead returns in order', () async {
      await db.progressDao.upsert(ReadingProgressCompanion(
        seriesId: const Value('s1'),
        currentItemId: const Value('i1'),
        pageIndex: const Value(0),
        updatedAt: Value(DateTime(2024, 1, 1)),
      ));
      await db.progressDao.upsert(ReadingProgressCompanion(
        seriesId: const Value('s2'),
        currentItemId: const Value('i2'),
        pageIndex: const Value(0),
        updatedAt: Value(DateTime(2024, 1, 2)),
      ));
      final recent = await db.progressDao.recentlyRead(limit: 10);
      expect(recent.first.seriesId, 's2');
    });
  });

  group('ManifestDao', () {
    late AppDatabase db;
    setUp(() => db = _makeDb());
    tearDown(() => db.close());

    test('upsert and mark deleted', () async {
      await db.manifestDao.upsert(SyncManifestCompanion(
        id: const Value('m1'),
        sourceId: const Value('src1'),
        remotePath: const Value('/remote/file.cbz'),
        cacheState: const Value('remote'),
      ));
      await db.manifestDao.markDeleted('m1');
      final row = await db.manifestDao.getById('m1');
      expect(row, isNotNull);
      expect(row!.userDeleted, isTrue);
    });

    test('bySource returns correct items', () async {
      await db.manifestDao.upsert(SyncManifestCompanion(
        id: const Value('m1'),
        sourceId: const Value('src1'),
        remotePath: const Value('/r/a.cbz'),
        cacheState: const Value('remote'),
      ));
      await db.manifestDao.upsert(SyncManifestCompanion(
        id: const Value('m2'),
        sourceId: const Value('src2'),
        remotePath: const Value('/r/b.cbz'),
        cacheState: const Value('remote'),
      ));
      final src1 = await db.manifestDao.bySource('src1');
      expect(src1.map((r) => r.id), contains('m1'));
      expect(src1.map((r) => r.id), isNot(contains('m2')));
    });
  });
}
