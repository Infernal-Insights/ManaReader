import 'dart:convert';
import 'package:http/http.dart' as http;

import 'metadata_provider.dart';

/// Queries the AniList GraphQL API for manga metadata.
class AniListProvider implements MetadataProvider {
  @override
  String get name => 'AniList';

  @override
  Future<Metadata?> search(String query) async {
    const url = 'https://graphql.anilist.co';
    const graphQuery = r'''
      query(\$search: String) {
        Media(search: \$search, type: MANGA) {
          title {
            romaji
            english
          }
          countryOfOrigin
          tags { name }
        }
      }
    ''';

    final body = jsonEncode({'query': graphQuery, 'variables': {'search': query}});

    try {
      final res = await http.post(Uri.parse(url),
          headers: {'Content-Type': 'application/json'}, body: body);
      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final media = data['data']?['Media'];
      if (media == null) return null;

      final title = (media['title']['english'] as String?) ??
          (media['title']['romaji'] as String?) ??
          query;
      final lang = (media['countryOfOrigin'] as String?) ?? 'unknown';
      final tags = (media['tags'] as List?)
              ?.map((e) => e['name'] as String)
              .toList() ??
          <String>[];

      return Metadata(title: title, language: lang, tags: tags);
    } catch (_) {
      return null;
    }
  }
}

