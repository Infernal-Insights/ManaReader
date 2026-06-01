// Metadata provider tests updated for new architecture.
// ComicInfo.xml parsing tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:mana_reader/core/comicinfo/comic_info_parser.dart';

void main() {
  group('ComicInfoParser', () {
    test('parses basic ComicInfo.xml', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<ComicInfo>
  <Title>My Comic</Title>
  <Series>My Series</Series>
  <Number>5</Number>
  <Volume>1</Volume>
  <Writer>Test Author</Writer>
  <LanguageISO>en</LanguageISO>
  <Genre>Action, Adventure</Genre>
</ComicInfo>''';

      final meta = ComicInfoParser.parse(xml);
      expect(meta.title, 'My Comic');
      expect(meta.series, 'My Series');
      expect(meta.chapter, 5);
      expect(meta.volume, 1);
      expect(meta.author, 'Test Author');
      expect(meta.language, 'en');
      expect(meta.tags, containsAll(['Action', 'Adventure']));
    });

    test('returns empty metadata for invalid xml', () {
      const xml = '<NotComicInfo/>';
      final meta = ComicInfoParser.parse(xml);
      expect(meta.title, isEmpty);
    });

    test('handles missing optional fields gracefully', () {
      const xml = '''<ComicInfo><Title>Only Title</Title></ComicInfo>''';
      final meta = ComicInfoParser.parse(xml);
      expect(meta.title, 'Only Title');
      expect(meta.author, isNull);
      expect(meta.tags, isEmpty);
    });
  });
}
