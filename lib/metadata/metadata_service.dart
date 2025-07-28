import 'metadata_provider.dart';
import 'anilist_provider.dart';
import 'doujindb_provider.dart';

/// Attempts to resolve metadata using all available providers.
class MetadataService {
  MetadataService()
      : _providers = [AniListProvider(), DoujinDbProvider()];

  final List<MetadataProvider> _providers;

  /// Queries each provider in order until one returns metadata.
  Future<Metadata?> resolve(String query) async {
    for (final provider in _providers) {
      final result = await provider.search(query);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}

