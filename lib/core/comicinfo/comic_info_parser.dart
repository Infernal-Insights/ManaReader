import 'package:xml/xml.dart';
import '../archive/comic_archive.dart';

/// Parses a ComicInfo.xml string into [ArchiveMetadata].
class ComicInfoParser {
  ComicInfoParser._();

  static ArchiveMetadata parse(String xmlString) {
    final doc = XmlDocument.parse(xmlString);
    final root = doc.findElements('ComicInfo').firstOrNull;
    if (root == null) {
      return const ArchiveMetadata(title: '');
    }

    String? text(String tag) =>
        root.findElements(tag).firstOrNull?.innerText.trim().nullIfEmpty();

    int? number(String tag) => int.tryParse(text(tag) ?? '');

    final tagsRaw = text('Genre') ?? text('Tags') ?? '';
    final tags = tagsRaw.isEmpty
        ? <String>[]
        : tagsRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return ArchiveMetadata(
      title: text('Title') ?? text('Series') ?? '',
      author: text('Writer') ?? text('Author'),
      series: text('Series'),
      volume: number('Volume'),
      chapter: number('Number'),
      language: text('LanguageISO'),
      tags: tags,
    );
  }
}

extension on String {
  String? nullIfEmpty() => isEmpty ? null : this;
}
