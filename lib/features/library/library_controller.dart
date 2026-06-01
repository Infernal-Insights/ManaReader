import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/db/database.dart';

// ---------------------------------------------------------------------------
// Library state
// ---------------------------------------------------------------------------

class LibraryState {
  final List<SeriesData> allSeries;
  final List<SeriesData> filtered;
  final String searchQuery;
  final String? activeShelfId;
  final bool isLoading;

  const LibraryState({
    this.allSeries = const [],
    this.filtered = const [],
    this.searchQuery = '',
    this.activeShelfId,
    this.isLoading = true,
  });

  LibraryState copyWith({
    List<SeriesData>? allSeries,
    List<SeriesData>? filtered,
    String? searchQuery,
    String? activeShelfId,
    bool? isLoading,
  }) {
    return LibraryState(
      allSeries: allSeries ?? this.allSeries,
      filtered: filtered ?? this.filtered,
      searchQuery: searchQuery ?? this.searchQuery,
      activeShelfId: activeShelfId ?? this.activeShelfId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LibraryController extends StateNotifier<LibraryState> {
  final AppDatabase _db;

  LibraryController(this._db) : super(const LibraryState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final series = await _db.seriesDao.allSeries();
      state = state.copyWith(
        allSeries: series,
        filtered: series,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _load();
  }

  void search(String query) {
    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? state.allSeries
        : state.allSeries
            .where((s) => s.title.toLowerCase().contains(q))
            .toList();
    state = state.copyWith(searchQuery: query, filtered: filtered);
  }

  void setShelf(String? shelfId) {
    state = state.copyWith(activeShelfId: shelfId);
  }

  Future<void> deleteSeries(String id) async {
    await _db.seriesDao.deleteById(id);
    await _db.progressDao.deleteForSeries(id);
    await _load();
  }
}

final libraryControllerProvider =
    StateNotifierProvider<LibraryController, LibraryState>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LibraryController(db);
});

// Shelves stream
final shelvesProvider = StreamProvider<List<ShelvesData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.shelvesDao.watchAll();
});

// Series stream (reactive)
final seriesStreamProvider = StreamProvider<List<SeriesData>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.seriesDao.watchAll();
});
