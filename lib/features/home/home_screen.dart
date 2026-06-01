import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/db/database.dart';
import '../library/library_controller.dart';
import '../library/series_card.dart';
import '../reader/reader_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final seriesAsync = ref.watch(seriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ManaReader'),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Continue reading row
          _ContinueReadingSection(db: db),
          const SizedBox(height: 16),
          // Recent additions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Library',
                    style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => context.go('/library'),
                  child: const Text('See all'),
                ),
              ],
            ),
          ),
          seriesAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Center(child: Text(e.toString())),
            data: (series) => series.isEmpty
                ? _EmptyLibraryCta(onTap: () => context.go('/sources'))
                : SizedBox(
                    height: 220,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: series.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final s = series[index];
                        return SizedBox(
                          width: 130,
                          child: SeriesCard(
                            series: s,
                            onTap: () => context.push('/reader/${s.id}'),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ContinueReadingSection extends StatefulWidget {
  final AppDatabase db;

  const _ContinueReadingSection({required this.db});

  @override
  State<_ContinueReadingSection> createState() =>
      _ContinueReadingSectionState();
}

class _ContinueReadingSectionState extends State<_ContinueReadingSection> {
  late final Future<List<_ProgressEntry>> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ProgressEntry>>(
      future: _progressFuture,
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        final entries = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Continue Reading',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            SizedBox(
              height: 80,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final e = entries[index];
                  return _ContinueCard(entry: e);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<_ProgressEntry>> _loadProgress() async {
    final recent = await widget.db.progressDao.recentlyRead(limit: 10);
    final entries = <_ProgressEntry>[];
    for (final p in recent) {
      final s = await widget.db.seriesDao.getById(p.seriesId);
      if (s != null) {
        entries.add(_ProgressEntry(series: s, progress: p));
      }
    }
    return entries;
  }
}

class _ProgressEntry {
  final SeriesData series;
  final ReadingProgressData progress;
  const _ProgressEntry({required this.series, required this.progress});
}

class _ContinueCard extends StatelessWidget {
  final _ProgressEntry entry;

  const _ContinueCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
          '/reader/${entry.series.id}?page=${entry.progress.pageIndex}'),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.menu_book, color: Colors.white54, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.series.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Page ${entry.progress.pageIndex + 1}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_arrow, color: Color(0xFF9B59B6)),
          ],
        ),
      ),
    );
  }
}

class _EmptyLibraryCta extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyLibraryCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.add_circle_outline, size: 64, color: Colors.white12),
          const SizedBox(height: 16),
          const Text('No comics yet',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onTap,
            child: const Text('Add a Source'),
          ),
        ],
      ),
    );
  }
}
