import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';
import 'library_controller.dart';

class ShelvesScreen extends ConsumerWidget {
  const ShelvesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelvesAsync = ref.watch(shelvesProvider);
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shelves')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createShelf(context, db),
        child: const Icon(Icons.add),
      ),
      body: shelvesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (shelves) => shelves.isEmpty
            ? const Center(
                child: Text('No shelves yet. Create one!',
                    style: TextStyle(color: Colors.white54)),
              )
            : ListView.builder(
                itemCount: shelves.length,
                itemBuilder: (context, index) {
                  final shelf = shelves[index];
                  final ids =
                      (jsonDecode(shelf.seriesIds) as List).cast<String>();
                  return ListTile(
                    leading: const Icon(Icons.bookmarks_outlined),
                    title: Text(shelf.name),
                    subtitle: Text('${ids.length} series'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => db.shelvesDao.deleteById(shelf.id),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _createShelf(BuildContext context, AppDatabase db) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Shelf'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Shelf name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              await db.shelvesDao.upsert(ShelvesCompanion(
                id: Value(const Uuid().v4()),
                name: Value(name),
              ));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
