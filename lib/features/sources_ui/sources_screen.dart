import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../reader/reader_controller.dart';

class SourcesScreen extends ConsumerStatefulWidget {
  const SourcesScreen({super.key});

  @override
  ConsumerState<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends ConsumerState<SourcesScreen> {
  @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sources')),
      body: FutureBuilder<List<SourceConfigData>>(
        future: db.sourceConfigDao.allConfigs(),
        builder: (context, snap) {
          final sources = snap.data ?? [];
          return sources.isEmpty
              ? _EmptySourcesState(
                  onAddLocal: () => context.push('/sources/add-local'),
                  onAddDrive: () => context.push('/sources/add-drive'),
                )
              : ListView.builder(
                  itemCount: sources.length,
                  itemBuilder: (context, index) {
                    final src = sources[index];
                    return _SourceTile(
                      source: src,
                      onDelete: () async {
                        await db.sourceConfigDao.deleteById(src.sourceId);
                        if (mounted) setState(() {});
                      },
                    );
                  },
                );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_local',
            onPressed: () => context.push('/sources/add-local'),
            icon: const Icon(Icons.folder_outlined),
            label: const Text('Local Folder'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_drive',
            onPressed: () => context.push('/sources/add-drive'),
            icon: const Icon(Icons.cloud_outlined),
            label: const Text('Google Drive'),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final SourceConfigData source;
  final VoidCallback onDelete;

  const _SourceTile({required this.source, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final icon = source.type == 'google_drive'
        ? Icons.cloud_outlined
        : Icons.folder_outlined;
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF9B59B6)),
      title: Text(source.sourceId),
      subtitle: Text(source.type),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: onDelete,
      ),
    );
  }
}

class _EmptySourcesState extends StatelessWidget {
  final VoidCallback onAddLocal;
  final VoidCallback onAddDrive;

  const _EmptySourcesState({required this.onAddLocal, required this.onAddDrive});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.source_outlined, size: 80, color: Colors.white12),
          const SizedBox(height: 20),
          const Text('No sources configured',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddLocal,
            icon: const Icon(Icons.folder_outlined),
            label: const Text('Add Local Folder'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAddDrive,
            icon: const Icon(Icons.cloud_outlined),
            label: const Text('Add Google Drive'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
          ),
        ],
      ),
    );
  }
}
