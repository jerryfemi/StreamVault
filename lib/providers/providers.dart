import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../data/models/channel.dart';
import '../data/models/epg_programme.dart';
import '../data/models/stream_status.dart';
import '../data/repositories/cache_manager.dart';
import '../data/repositories/channel_repository.dart';
import '../data/repositories/epg_repository.dart';
import '../data/services/epg_service.dart';
import '../data/services/m3u_service.dart';
import '../data/services/registry_service.dart';
import 'favorites_notifier.dart';
import 'stream_status_notifier.dart';

// ═══════════════════════════════════════════════════════════════════
// INFRASTRUCTURE PROVIDERS
// ═══════════════════════════════════════════════════════════════════

final httpClientProvider = Provider<http.Client>((ref) => http.Client());
final cacheManagerProvider = Provider<CacheManager>((ref) => CacheManager());

// ═══════════════════════════════════════════════════════════════════
// SERVICE PROVIDERS
// ═══════════════════════════════════════════════════════════════════

final m3uServiceProvider = Provider<M3uService>(
  (ref) => M3uService(client: ref.watch(httpClientProvider)),
);

final registryServiceProvider = Provider<RegistryService>(
  (ref) => RegistryService(client: ref.watch(httpClientProvider)),
);

final epgServiceProvider = Provider<EpgService>((ref) => EpgService());

// ═══════════════════════════════════════════════════════════════════
// REPOSITORY PROVIDERS
// ═══════════════════════════════════════════════════════════════════

final channelRepoProvider = Provider<ChannelRepository>(
  (ref) => ChannelRepository(
    ref.watch(m3uServiceProvider),
    ref.watch(registryServiceProvider),
    ref.watch(cacheManagerProvider),
  ),
);

final epgRepoProvider = Provider<EpgRepository>(
  (ref) => EpgRepository(ref.watch(epgServiceProvider)),
);

// ═══════════════════════════════════════════════════════════════════
// DATA PROVIDERS
// ═══════════════════════════════════════════════════════════════════

/// All verified channels (Sports + Movies combined).
final allChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  return ref.watch(channelRepoProvider).getChannels([
    AppConstants.sportsM3uUrl,
    AppConstants.moviesM3uUrl,
  ]);
});

/// EPG schedule — refreshes every hour, holds a 24h forward window per channel.
final epgScheduleProvider = FutureProvider<void>((ref) async {
  await ref.watch(epgRepoProvider).refresh();
});

/// Current programme for a given channel — what's playing right now.
final nowPlayingProvider =
    Provider.family<EpgProgramme?, String>((ref, channelId) {
  ref.watch(epgScheduleProvider);
  return ref.watch(epgRepoProvider).getCurrent(channelId);
});

/// Next programme for a given channel — powers the "Up Next" section in the player.
final upNextProvider =
    Provider.family<EpgProgramme?, String>((ref, channelId) {
  ref.watch(epgScheduleProvider);
  return ref.watch(epgRepoProvider).getNext(channelId);
});

/// Stream validation status map — updates progressively as cards become visible.
final streamStatusProvider =
    StateNotifierProvider<StreamStatusNotifier, Map<String, StreamStatus>>(
  (ref) => StreamStatusNotifier(),
);

/// Favorites provider for managing favorite channels.
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);

// ═══════════════════════════════════════════════════════════════════
// UI-FACING PROVIDERS (derived, cheap)
// ═══════════════════════════════════════════════════════════════════

/// Active category filter.
final activeCategoryProvider = StateProvider<String>((ref) => 'Sports');

/// Search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered channel list — recomputes when category or search changes.
final filteredChannelsProvider = Provider<AsyncValue<List<Channel>>>((ref) {
  final channels = ref.watch(allChannelsProvider);
  final category = ref.watch(activeCategoryProvider);
  final query = ref.watch(searchQueryProvider);
  final favorites = ref.watch(favoritesProvider);

  return channels.whenData((list) => list.where((c) {
        final matchesCategory = category == 'Favorites'
            ? favorites.contains(c.id)
            : c.category == category;
        final matchesSearch = query.isEmpty ||
            c.name.toLowerCase().contains(query.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList());
});
