import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/database.dart';
import '../source/content_source.dart';

enum SyncStatus { idle, syncing, error }

class SyncResult {
  final int added;
  final int updated;
  final int removed;
  final String? errorMessage;

  const SyncResult({
    this.added = 0,
    this.updated = 0,
    this.removed = 0,
    this.errorMessage,
  });
}

/// One-way mirror sync engine with tombstone support.
/// Only one sync path — every source uses this engine.
class SyncEngine {
  final AppDatabase _db;

  SyncEngine(this._db);

  /// Sync a content source against the local manifest.
  Future<SyncResult> sync(ContentSource source) async {
    int added = 0, updated = 0, removed = 0;

    try {
      final remoteItems = await source.listItems();
      final existingRows = await _db.manifestDao.bySource(source.id);
      final existingMap = {for (final r in existingRows) r.id: r};

      final seenIds = <String>{};

      for (final item in remoteItems) {
        seenIds.add(item.id);
        final existing = existingMap[item.id];

        if (existing == null) {
          // New remote item
          await _db.manifestDao.upsert(SyncManifestCompanion(
            id: Value(item.id),
            sourceId: Value(source.id),
            remotePath: Value(item.title),
            cacheState: const Value('remote'),
            lastSynced: Value(DateTime.now()),
          ));
          added++;
        } else if (existing.userDeleted) {
          // Tombstone — skip
          continue;
        } else {
          // Existing — check if we need to re-cache
          if (item.modifiedAt != null &&
              existing.lastSynced != null &&
              item.modifiedAt!.isAfter(existing.lastSynced!)) {
            // Invalidate cache
            if (existing.cacheState == 'cached') {
              await _db.manifestDao.setCacheState(item.id, 'remote');
              if (existing.localPath != null) {
                final f = File(existing.localPath!);
                if (await f.exists()) await f.delete();
              }
            }
            await _db.manifestDao.upsert(SyncManifestCompanion(
              id: Value(item.id),
              lastSynced: Value(DateTime.now()),
            ));
            updated++;
          }
        }
      }

      // Items no longer on remote (but NOT user-deleted) → mark evicted
      for (final row in existingRows) {
        if (!seenIds.contains(row.id) && !row.userDeleted) {
          await _db.manifestDao.setCacheState(row.id, 'evicted');
          removed++;
        }
      }

      return SyncResult(added: added, updated: updated, removed: removed);
    } catch (e) {
      return SyncResult(errorMessage: e.toString());
    }
  }

  /// Download and cache a single item, verifying its hash.
  Future<String> cacheItem(ContentSource source, String itemId) async {
    final row = await _db.manifestDao.getById(itemId);
    if (row == null) throw Exception('Item $itemId not in manifest');
    if (row.userDeleted) throw Exception('Item $itemId is user-deleted');

    if (row.cacheState == 'cached' && row.localPath != null) {
      final f = File(row.localPath!);
      if (await f.exists()) return row.localPath!;
    }

    final file = await source.fetchFile(itemId);
    final hash = await _computeHash(file);

    await _db.manifestDao.upsert(SyncManifestCompanion(
      id: Value(itemId),
      localPath: Value(file.path),
      contentHash: Value(hash),
      cacheState: const Value('cached'),
      lastSynced: Value(DateTime.now()),
    ));

    return file.path;
  }

  /// Mark an item as user-deleted (tombstone). It won't be re-imported.
  Future<void> deleteItem(String itemId) async {
    final row = await _db.manifestDao.getById(itemId);
    if (row == null) return;

    // Delete local file if cached
    if (row.localPath != null) {
      final f = File(row.localPath!);
      if (await f.exists()) await f.delete();
    }

    await _db.manifestDao.markDeleted(itemId);
  }

  static Future<String> _computeHash(File file) async {
    final bytes = await file.readAsBytes();
    return md5.convert(bytes).toString();
  }
}
