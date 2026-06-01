import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'library_controller.dart';
import 'series_card.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(libraryControllerProvider);
    final ctrl = ref.read(libraryControllerProvider.notifier);
    final shelves = ref.watch(shelvesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search series…',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: ctrl.search,
              )
            : const Text('Library'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _searchCtrl.clear();
                  ctrl.search('');
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'Shelves',
            onPressed: () => context.go('/library/shelves'),
          ),
        ],
      ),
      body: state.isLoading
          ? const _SkeletonGrid()
          : state.filtered.isEmpty
              ? _EmptyState(onAddSource: () => context.go('/sources/add-local'))
              : RefreshIndicator(
                  onRefresh: ctrl.refresh,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: state.filtered.length,
                    itemBuilder: (context, index) {
                      final s = state.filtered[index];
                      return SeriesCard(
                        series: s,
                        onTap: () => context.push('/reader/${s.id}'),
                        onLongPress: () => _showSeriesOptions(context, s.id, ctrl),
                      );
                    },
                  ),
                ),
    );
  }

  void _showSeriesOptions(
      BuildContext context, String id, LibraryController ctrl) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove from library',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ctrl.deleteSeries(id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddSource;

  const _EmptyState({required this.onAddSource});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.collections_bookmark_outlined,
              size: 80, color: Colors.white12),
          const SizedBox(height: 20),
          Text('Your library is empty',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white54)),
          const SizedBox(height: 8),
          Text('Add a source to get started',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white38)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddSource,
            icon: const Icon(Icons.add),
            label: const Text('Add Local Folder'),
          ),
        ],
      ),
    );
  }
}

class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.62,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 12,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
