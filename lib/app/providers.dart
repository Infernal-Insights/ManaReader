import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/db/database.dart';

/// Single app-level database instance, shared across all features.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
