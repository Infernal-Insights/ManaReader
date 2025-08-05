import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'metadata_provider.dart';

/// Queries the DoujinDB REST API for doujin metadata.
class DoujinDbProvider implements MetadataProvider {
  DoujinDbProvider({http.Client? client, this.timeout = const Duration(seconds: 5)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  @override
  String get name => 'DoujinDB';

  @override
  Future<Metadata?> search(String query) async {
    final url = Uri.parse('https://doujindb.truesight.xyz/api/search?q=$query');

    try {
      final res = await _client.get(url).timeout(timeout);
      if (res.statusCode != 200) {
        debugPrint('DoujinDbProvider search failed: HTTP ${res.statusCode}');
        return null;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;

      final title = first['title'] as String? ?? query;
      final lang = first['language'] as String? ?? 'unknown';
      final tags = (first['tags'] as List?)?.cast<String>() ?? <String>[];

      return Metadata(title: title, language: lang, tags: tags);
    } on TimeoutException catch (e) {
      debugPrint('DoujinDbProvider search timeout: $e');
      return null;
    } catch (e, st) {
      debugPrint('DoujinDbProvider search error: $e');
      debugPrintStack(stackTrace: st);
      return null;
    }
  }
}

