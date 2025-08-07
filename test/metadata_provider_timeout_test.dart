import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mana_reader/metadata/anilist_provider.dart';
import 'package:mana_reader/metadata/doujindb_provider.dart';
import 'package:mana_reader/metadata/metadata_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> checkTimeout(MetadataProvider provider) async {
    final messages = <String?>[];
    final orig = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      messages.add(message);
    };
    addTearDown(() => debugPrint = orig);

    final result = await provider.search('query');
    expect(result, isNull);
    expect(messages.any((m) => m?.contains('timeout') ?? false), isTrue);
  }

  test('AniListProvider logs timeout', () async {
    final client = MockClient((request) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return http.Response('{}', 200);
    });
    final provider = AniListProvider(
      client: client,
      timeout: const Duration(milliseconds: 10),
    );
    await checkTimeout(provider);
  });

  test('DoujinDbProvider logs timeout', () async {
    final client = MockClient((request) async {
      await Future.delayed(const Duration(milliseconds: 100));
      return http.Response('{}', 200);
    });
    final provider = DoujinDbProvider(
      client: client,
      timeout: const Duration(milliseconds: 10),
    );
    await checkTimeout(provider);
  });
}
