import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/db/database.dart';
import '../../core/source/local_folder_source.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/series/series_grouper.dart';
import '../../core/archive/archive_factory.dart';
import '../reader/reader_controller.dart';

class AddLocalSourceScreen extends ConsumerStatefulWidget {
  const AddLocalSourceScreen({super.key});

  @override
  ConsumerState<AddLocalSourceScreen> createState() =>
      _AddLocalSourceScreenState();
}

class _AddLocalSourceScreenState
    extends ConsumerState<AddLocalSourceScreen> {
  String? _selectedPath;
  bool _scanning = false;
  String? _error;
  int _foundCount = 0;

  Future<void> _pickFolder() async {
    try {
      final path = await getDirectoryPath();
      if (path == null) return;
      setState(() {
        _selectedPath = path;
        _foundCount = 0;
        _error = null;
      });
      await _scan(path);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _scan(String path) async {
    setState(() => _scanning = true);
    try {
      final source = LocalFolderSource(
        id: 'local_${const Uuid().v4()}',
        folderPath: path,
      );
      final items = await source.listItems();
      setState(() {
        _foundCount = items.length;
        _scanning = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _scanning = false;
      });
    }
  }

  Future<void> _addSource() async {
    if (_selectedPath == null) return;
    setState(() => _scanning = true);

    try {
      final db = ref.read(appDatabaseProvider);
      final sourceId = 'local_${const Uuid().v4()}';
      final source = LocalFolderSource(
        id: sourceId,
        folderPath: _selectedPath!,
        displayName: p.basename(_selectedPath!),
      );

      // Persist config
      await db.sourceConfigDao.upsert(SourceConfigCompanion(
        sourceId: Value(sourceId),
        type: const Value('local'),
        configJson: Value(jsonEncode({'path': _selectedPath})),
      ));

      // Run initial sync
      final engine = SyncEngine(db);
      await engine.sync(source);

      // Import series metadata
      final items = await source.listItems();
      for (final item in items) {
        try {
          final archive = ArchiveFactory.fromPath(item.id);
          final meta = archive.metadata;
          await archive.dispose();

          final seriesTitle = meta.series?.isNotEmpty == true
              ? meta.series!
              : SeriesGrouper.extract(item.title)?.series ?? item.title;
          final sid = SeriesGrouper.seriesId(seriesTitle);

          await db.seriesDao.upsert(SeriesCompanion(
            id: Value(sid),
            title: Value(seriesTitle),
            author: Value(meta.author),
            sortKey: Value(seriesTitle.toLowerCase()),
          ));

          await db.manifestDao.upsert(SyncManifestCompanion(
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

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${items.length} items from source')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _scanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Local Folder')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select a folder containing your comics or manga.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _scanning ? null : _pickFolder,
              icon: const Icon(Icons.folder_open),
              label: const Text('Choose Folder'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white30),
              ),
            ),
            if (_selectedPath != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPath!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    if (_scanning)
                      const Row(children: [
                        SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 8),
                        Text('Scanning...', style: TextStyle(color: Colors.white54)),
                      ])
                    else
                      Text('$_foundCount comic files found',
                          style: const TextStyle(
                              color: Color(0xFF9B59B6),
                              fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: (_selectedPath != null && !_scanning && _foundCount > 0)
                  ? _addSource
                  : null,
              child: const Text('Add Source'),
            ),
          ],
        ),
      ),
    );
  }
}
