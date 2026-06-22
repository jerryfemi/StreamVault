import '../models/channel.dart';
import '../models/raw_m3u_entry.dart';
import '../services/m3u_service.dart';
import '../services/registry_service.dart';
import 'cache_manager.dart';

class ChannelRepository {
  final M3uService _m3uService;
  final RegistryService _registryService;
  final CacheManager _cache;

  ChannelRepository(this._m3uService, this._registryService, this._cache);

  Future<List<Channel>> getChannels(List<String> categoryUrls) async {
    // Check cache first
    final cached = await _cache.getChannels();
    if (cached != null) return cached;

    // Fetch in parallel — registry, streams metadata, and M3Us
    final results = await Future.wait([
      _registryService.fetchVerifiedIds(),
      _registryService.fetchStreamMetadata(),
      ...categoryUrls.map((url) => _m3uService.fetchCategory(url)),
    ]);

    final verifiedIds = results[0] as Set<String>;
    final streamMetadataMap = results[1] as Map<String, StreamMetadata>;
    final allEntries = results
        .sublist(2)
        .expand((list) => list as List<RawM3uEntry>)
        .toList();

    final channels = allEntries
        .map((e) {
          final meta = streamMetadataMap[e.streamUrl]; // Exact match by URL
          return Channel.fromRaw(
            e,
            headers: meta?.headers ?? const {},
            quality: meta?.quality,
          );
        })
        .where(
          (c) =>
              c.streamUrl.isNotEmpty &&
              c.tvgId.isNotEmpty &&
              verifiedIds.contains(c.tvgId.split('@').first),
        ) // THE QUALITY GATE
        .toList();

    await _cache.saveChannels(channels);
    return channels;
  }
}
