import 'package:uuid/uuid.dart';

import '../archive/comic_archive.dart';

/// Groups archive filenames into series using pattern matching.
///
/// Example patterns:
///   "Berserk v01.cbz"  → series "Berserk", volume 1
///   "One Piece - 001.cbz" → series "One Piece", chapter 1
///   "Naruto_ch001.cbz" → series "Naruto", chapter 1
class SeriesGrouper {
  SeriesGrouper._();

  static const _uuid = Uuid();

  // Patterns: (regex, namedGroupsExtractor)
  static final _patterns = <_PatternDef>[
    // "Title v01" or "Title Vol.1"
    _PatternDef(
      RegExp(r'^(.+?)\s+[Vv]ol?\.?\s*(\d+)', caseSensitive: false),
      (m) => SeriesExtractResult(
        series: m.group(1)!.trim(),
        volume: int.tryParse(m.group(2)!),
      ),
    ),
    // "Title - 001" or "Title ch001"
    _PatternDef(
      RegExp(r'^(.+?)\s*[-_]\s*(?:ch\.?\s*)?(\d+)', caseSensitive: false),
      (m) => SeriesExtractResult(
        series: m.group(1)!.trim(),
        chapter: int.tryParse(m.group(2)!),
      ),
    ),
    // "Title #001"
    _PatternDef(
      RegExp(r'^(.+?)\s*#\s*(\d+)', caseSensitive: false),
      (m) => SeriesExtractResult(
        series: m.group(1)!.trim(),
        chapter: int.tryParse(m.group(2)!),
      ),
    ),
  ];

  /// Attempt to extract series info from a filename (without extension).
  static SeriesExtractResult? extract(String baseName) {
    for (final pat in _patterns) {
      final m = pat.pattern.firstMatch(baseName);
      if (m != null) return pat.extract(m);
    }
    return null;
  }

  /// Group a list of [ArchiveMetadata] (keyed by path) into series buckets.
  /// Returns a map of seriesTitle → list of paths.
  static Map<String, List<String>> group(Map<String, ArchiveMetadata> items) {
    final result = <String, List<String>>{};

    for (final entry in items.entries) {
      final path = entry.key;
      final meta = entry.value;

      // Prefer ComicInfo.xml series name
      String seriesTitle = meta.series ?? '';
      if (seriesTitle.isEmpty) {
        final extracted = extract(meta.title);
        seriesTitle = extracted?.series ?? meta.title;
      }

      result.putIfAbsent(seriesTitle, () => []).add(path);
    }

    return result;
  }

  /// Generate a deterministic series ID from the title.
  static String seriesId(String title) {
    return _uuid.v5(Uuid.NAMESPACE_URL, 'mana:series:$title');
  }
}

class SeriesExtractResult {
  final String series;
  final int? volume;
  final int? chapter;

  const SeriesExtractResult({required this.series, this.volume, this.chapter});
}

class _PatternDef {
  final RegExp pattern;
  final SeriesExtractResult Function(Match) extract;
  const _PatternDef(this.pattern, this.extract);
}
