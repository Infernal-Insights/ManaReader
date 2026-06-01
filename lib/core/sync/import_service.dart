import 'package:drift/drift.dart' show Value;

import '../archive/archive_factory.dart';
import '../db/database.dart';
import '../series/series_grouper.dart';
import '../source/content_source.dart';

/// Imports a list of [SourceItem]s into the database, grouping them into series.
/// This is the only place that bridges archive metadata → library records.
class ImportService {
  final AppDatabase _db;

  ImportService(this._db);

  Future<void> importItems(
    List<SourceItem> items,
    String sourceId,
  ) async {
    for (final item in items) {
      try {
        final archive = ArchiveFactory.fromPath(item.id);
        final meta = archive.metadata;
        await archive.dispose();

        final seriesTitle = meta.series?.isNotEmpty == true
            ? meta.series!
            : SeriesGrouper.extract(item.title)?.series ?? item.title;
        final sid = SeriesGrouper.seriesId(seriesTitle);

        await _db.seriesDao.upsert(SeriesCompanion(
          id: Value(sid),
          title: Value(seriesTitle),
          author: Value(meta.author),
          sortKey: Value(seriesTitle.toLowerCase()),
        ));

        await _db.manifestDao.upsert(SyncManifestCompanion(
          id: Value(item.id),
          sourceId: Value(sourceId),
          remotePath: Value(item.id),
          localPath: Value(item.id),
          cacheState: const Value('cached'),
          seriesId: Value(sid),
          lastSynced: Value(DateTime.now()),
        ));
      } catch (_) {
        // Skip unreadable files
      }
    }
  }
}
