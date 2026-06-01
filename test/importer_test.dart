// Importer tests updated for new architecture — tests series grouper.
import 'package:flutter_test/flutter_test.dart';
import 'package:mana_reader/core/series/series_grouper.dart';

void main() {
  group('SeriesGrouper.extract', () {
    test('extracts volume pattern', () {
      final r = SeriesGrouper.extract('Berserk v01');
      expect(r, isNotNull);
      expect(r!.series, 'Berserk');
      expect(r.volume, 1);
    });

    test('extracts chapter pattern with dash', () {
      final r = SeriesGrouper.extract('One Piece - 001');
      expect(r, isNotNull);
      expect(r!.series, 'One Piece');
    });

    test('extracts hash pattern', () {
      final r = SeriesGrouper.extract('Naruto #042');
      expect(r, isNotNull);
      expect(r!.series, 'Naruto');
      expect(r.chapter, 42);
    });

    test('returns null for non-matching title', () {
      final r = SeriesGrouper.extract('standalone');
      expect(r, isNull);
    });
  });

  group('SeriesGrouper.seriesId', () {
    test('same title produces same id', () {
      final id1 = SeriesGrouper.seriesId('Berserk');
      final id2 = SeriesGrouper.seriesId('Berserk');
      expect(id1, id2);
    });

    test('different titles produce different ids', () {
      final id1 = SeriesGrouper.seriesId('Berserk');
      final id2 = SeriesGrouper.seriesId('Naruto');
      expect(id1, isNot(id2));
    });
  });
}
