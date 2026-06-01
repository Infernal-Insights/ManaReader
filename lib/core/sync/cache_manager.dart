import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../db/database.dart';
import 'cache_state.dart';

/// Manages local cache of downloaded files.
class CacheManager {
  final AppDatabase _db;

  CacheManager(this._db);

  Future<Directory> get _cacheDir async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory(p.join(base.path, 'comic_cache'));
    await dir.create(recursive: true);
    return dir;
  }

  /// Evict a single cached file, setting state back to 'remote'.
  Future<void> evict(String itemId) async {
    final row = await _db.manifestDao.getById(itemId);
    if (row == null) return;
    if (row.localPath != null) {
      final f = File(row.localPath!);
      if (await f.exists()) await f.delete();
    }
    await _db.manifestDao.upsert(SyncManifestCompanion(
      id: Value(itemId),
      localPath: const Value.absent(),
      cacheState: Value(CacheState.evicted.value),
    ));
  }

  /// Evict all cached files for a source.
  Future<void> evictSource(String sourceId) async {
    final rows = await _db.manifestDao.bySource(sourceId);
    for (final row in rows) {
      if (row.cacheState == CacheState.cached.value && row.localPath != null) {
        final f = File(row.localPath!);
        if (await f.exists()) await f.delete();
        await _db.manifestDao.setCacheState(row.id, CacheState.evicted.value);
      }
    }
  }

  /// Returns total bytes used by cached files.
  Future<int> totalCacheBytes() async {
    final dir = await _cacheDir;
    int total = 0;
    await for (final f in dir.list(recursive: true)) {
      if (f is File) {
        try {
          total += await f.length();
        } catch (_) {}
      }
    }
    return total;
  }

  /// Evict all cache files and reset states.
  Future<void> clearAll() async {
    final dir = await _cacheDir;
    if (await dir.exists()) await dir.delete(recursive: true);
    // Reset all cached rows
    final rows = await _db.manifestDao.allItems();
    for (final row in rows) {
      if (row.cacheState == CacheState.cached.value) {
        await _db.manifestDao.setCacheState(row.id, CacheState.evicted.value);
      }
    }
  }
}
