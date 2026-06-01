import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// Tables
// ---------------------------------------------------------------------------

class SyncManifest extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text()();
  TextColumn get remotePath => text()();
  TextColumn get localPath => text().nullable()();
  TextColumn get contentHash => text().nullable()();
  DateTimeColumn get lastSynced => dateTime().nullable()();
  BoolColumn get userDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get cacheState => text().withDefault(const Constant('remote'))();
  // remote | cached | evicted
  TextColumn get seriesId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Series extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get author => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  TextColumn get sortKey => text()();
  IntColumn get totalItems => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class ReadingProgress extends Table {
  TextColumn get seriesId => text()();
  TextColumn get currentItemId => text()();
  IntColumn get pageIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {seriesId};
}

class Shelves extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get seriesIds => text().withDefault(const Constant('[]'))();
  // JSON array of series IDs

  @override
  Set<Column> get primaryKey => {id};
}

class SourceConfig extends Table {
  TextColumn get sourceId => text()();
  TextColumn get type => text()(); // 'local' | 'google_drive'
  TextColumn get configJson => text().withDefault(const Constant('{}'))();

  @override
  Set<Column> get primaryKey => {sourceId};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [SyncManifest, Series, ReadingProgress, Shelves, SourceConfig],
  daos: [ManifestDao, SeriesDao, ProgressDao, ShelvesDao, SourceConfigDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Future migrations here
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA journal_mode=WAL');
          await customStatement('PRAGMA foreign_keys=ON');
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'mana_reader');
  }
}

// ---------------------------------------------------------------------------
// DAOs (inline — separate files will re-export these)
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [SyncManifest])
class ManifestDao extends DatabaseAccessor<AppDatabase> with _$ManifestDaoMixin {
  ManifestDao(super.db);

  Future<List<SyncManifestData>> allItems() => select(syncManifest).get();

  Future<SyncManifestData?> getById(String id) =>
      (select(syncManifest)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<SyncManifestData>> bySource(String sourceId) =>
      (select(syncManifest)..where((t) => t.sourceId.equals(sourceId))).get();

  Future<List<SyncManifestData>> bySeries(String seriesId) =>
      (select(syncManifest)..where((t) => t.seriesId.equals(seriesId))).get();

  Future<void> upsert(SyncManifestCompanion entry) =>
      into(syncManifest).insertOnConflictUpdate(entry);

  Future<void> markDeleted(String id) => (update(syncManifest)
        ..where((t) => t.id.equals(id)))
      .write(const SyncManifestCompanion(userDeleted: Value(true)));

  Future<void> setCacheState(String id, String state) =>
      (update(syncManifest)..where((t) => t.id.equals(id)))
          .write(SyncManifestCompanion(cacheState: Value(state)));

  Future<void> deleteById(String id) =>
      (delete(syncManifest)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [Series])
class SeriesDao extends DatabaseAccessor<AppDatabase> with _$SeriesDaoMixin {
  SeriesDao(super.db);

  Future<List<SeriesData>> allSeries() =>
      (select(series)..orderBy([(t) => OrderingTerm.asc(t.sortKey)])).get();

  Stream<List<SeriesData>> watchAll() =>
      (select(series)..orderBy([(t) => OrderingTerm.asc(t.sortKey)])).watch();

  Future<SeriesData?> getById(String id) =>
      (select(series)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsert(SeriesCompanion entry) =>
      into(series).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(series)..where((t) => t.id.equals(id))).go();

  Future<List<SeriesData>> search(String query) => (select(series)
        ..where((t) => t.title.like('%$query%')))
      .get();
}

@DriftAccessor(tables: [ReadingProgress])
class ProgressDao extends DatabaseAccessor<AppDatabase>
    with _$ProgressDaoMixin {
  ProgressDao(super.db);

  Future<ReadingProgressData?> getProgress(String seriesId) =>
      (select(readingProgress)..where((t) => t.seriesId.equals(seriesId)))
          .getSingleOrNull();

  Stream<ReadingProgressData?> watchProgress(String seriesId) =>
      (select(readingProgress)..where((t) => t.seriesId.equals(seriesId)))
          .watchSingleOrNull();

  Future<List<ReadingProgressData>> recentlyRead({int limit = 20}) =>
      (select(readingProgress)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(limit))
          .get();

  Future<void> upsert(ReadingProgressCompanion entry) =>
      into(readingProgress).insertOnConflictUpdate(entry);

  Future<void> deleteForSeries(String seriesId) =>
      (delete(readingProgress)..where((t) => t.seriesId.equals(seriesId)))
          .go();
}

@DriftAccessor(tables: [Shelves])
class ShelvesDao extends DatabaseAccessor<AppDatabase> with _$ShelvesDaoMixin {
  ShelvesDao(super.db);

  Future<List<ShelvesData>> allShelves() => select(shelves).get();
  Stream<List<ShelvesData>> watchAll() => select(shelves).watch();

  Future<ShelvesData?> getById(String id) =>
      (select(shelves)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsert(ShelvesCompanion entry) =>
      into(shelves).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(shelves)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [SourceConfig])
class SourceConfigDao extends DatabaseAccessor<AppDatabase>
    with _$SourceConfigDaoMixin {
  SourceConfigDao(super.db);

  Future<List<SourceConfigData>> allConfigs() => select(sourceConfig).get();

  Future<SourceConfigData?> getById(String sourceId) =>
      (select(sourceConfig)..where((t) => t.sourceId.equals(sourceId)))
          .getSingleOrNull();

  Future<void> upsert(SourceConfigCompanion entry) =>
      into(sourceConfig).insertOnConflictUpdate(entry);

  Future<void> deleteById(String sourceId) =>
      (delete(sourceConfig)..where((t) => t.sourceId.equals(sourceId))).go();
}
