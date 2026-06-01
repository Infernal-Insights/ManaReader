import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/archive/comic_archive.dart';
import '../../core/archive/archive_factory.dart';
import '../../core/db/database.dart';
import 'reader_settings.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ---------------------------------------------------------------------------
// Reader state
// ---------------------------------------------------------------------------

class ReaderState {
  final String seriesId;
  final String filePath;
  final int pageCount;
  final int currentPage;
  final ReaderSettings settings;
  final bool isLoading;
  final String? error;

  const ReaderState({
    required this.seriesId,
    required this.filePath,
    required this.pageCount,
    required this.currentPage,
    required this.settings,
    this.isLoading = false,
    this.error,
  });

  ReaderState copyWith({
    int? currentPage,
    int? pageCount,
    ReaderSettings? settings,
    bool? isLoading,
    String? error,
  }) {
    return ReaderState(
      seriesId: seriesId,
      filePath: filePath,
      pageCount: pageCount ?? this.pageCount,
      currentPage: currentPage ?? this.currentPage,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ReaderController extends StateNotifier<AsyncValue<ReaderState>> {
  final AppDatabase _db;
  final String _seriesId;
  final int _initialPage;
  ComicArchive? _archive;

  // Page image cache
  final Map<int, Uint8List> _pageCache = {};

  ReaderController({
    required AppDatabase db,
    required String seriesId,
    required int initialPage,
  })  : _db = db,
        _seriesId = seriesId,
        _initialPage = initialPage,
        super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      // Find the file path from the manifest
      final items = await _db.manifestDao.bySeries(_seriesId);
      if (items.isEmpty) throw Exception('No items found for series $_seriesId');

      // For now open the first item (simplification for V1)
      final item = items.first;
      final path = item.localPath ?? item.remotePath;

      _archive = ArchiveFactory.fromPath(path);
      final count = await _archive!.pageCount;

      // Load saved progress
      final progress = await _db.progressDao.getProgress(_seriesId);
      final startPage = progress?.pageIndex ?? _initialPage;

      state = AsyncValue.data(ReaderState(
        seriesId: _seriesId,
        filePath: path,
        pageCount: count,
        currentPage: startPage.clamp(0, count - 1),
        settings: const ReaderSettings(),
      ));

      // Pre-render first pages
      _prerender(startPage);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Uint8List?> getPageBytes(int index) async {
    if (_pageCache.containsKey(index)) return _pageCache[index];
    try {
      final page = await _archive!.getPage(index);
      _pageCache[index] = page.bytes;
      return page.bytes;
    } catch (_) {
      return null;
    }
  }

  void goToPage(int page) {
    state.whenData((s) {
      final clamped = page.clamp(0, s.pageCount - 1);
      state = AsyncValue.data(s.copyWith(currentPage: clamped));
      _saveProgress(clamped);
      _prerender(clamped);
    });
  }

  void nextPage() {
    state.whenData((s) => goToPage(s.currentPage + 1));
  }

  void prevPage() {
    state.whenData((s) => goToPage(s.currentPage - 1));
  }

  void updateSettings(ReaderSettings settings) {
    state.whenData((s) {
      state = AsyncValue.data(s.copyWith(settings: settings));
    });
  }

  Future<void> _saveProgress(int page) async {
    await _db.progressDao.upsert(ReadingProgressCompanion(
      seriesId: Value(_seriesId),
      currentItemId: Value(_seriesId),
      pageIndex: Value(page),
      updatedAt: Value(DateTime.now()),
    ));
  }

  void _prerender(int currentPage) {
    state.whenData((s) {
      for (var i = currentPage + 1; i <= currentPage + 3 && i < s.pageCount; i++) {
        if (!_pageCache.containsKey(i)) {
          getPageBytes(i); // fire and forget
        }
      }
    });
  }

  @override
  void dispose() {
    _archive?.dispose();
    super.dispose();
  }
}

// Provider family
final readerControllerProvider = StateNotifierProvider.family<
    ReaderController, AsyncValue<ReaderState>, (String, int)>(
  (ref, args) {
    final db = ref.watch(appDatabaseProvider);
    return ReaderController(
      db: db,
      seriesId: args.$1,
      initialPage: args.$2,
    );
  },
);
