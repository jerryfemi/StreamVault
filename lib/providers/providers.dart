import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../data/models/channel.dart';
import '../data/models/epg_programme.dart';
import '../data/models/remote_config.dart';
import '../data/models/stream_status.dart';
import '../data/repositories/cache_manager.dart';
import '../data/repositories/channel_repository.dart';
import '../data/repositories/epg_repository.dart';
import '../data/services/epg_service.dart';
import '../data/services/github_config_service.dart';
import '../data/services/m3u_service.dart';
import '../data/services/registry_service.dart';
import 'admin_settings_notifier.dart';

export 'admin_settings_notifier.dart';
export 'admin_custom_epg_notifier.dart';
import 'dead_channels_notifier.dart';
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

/// EPG schedule map — the actual parsed data, reactive.
/// When this completes, all nowPlayingProvider/upNextProvider watchers rebuild.
final epgScheduleProvider = FutureProvider<Map<String, List<EpgProgramme>>>((
  ref,
) async {
  final service = ref.watch(epgServiceProvider);
  return service.fetchSchedule();
});

/// Current programme for a given channel — what's playing right now.
final nowPlayingProvider = Provider.family<EpgProgramme?, String>((
  ref,
  channelId,
) {
  // Check for an active custom EPG entry first
  final remoteConfig =
      ref.watch(remoteConfigProvider).valueOrNull ?? RemoteConfig.empty;
  final customEpg = remoteConfig.customEpg[channelId];
  if (customEpg != null) {
    final now = DateTime.now();
    if (now.isAfter(customEpg.start) && now.isBefore(customEpg.end)) {
      return EpgProgramme(
        channelId: channelId,
        title: customEpg.title,
        start: customEpg.start,
        end: customEpg.end,
        description: customEpg.description.isNotEmpty
            ? customEpg.description
            : 'Live Broadcast',
      );
    }
  }

  // Fallback to standard XMLTV EPG
  final scheduleAsync = ref.watch(epgScheduleProvider);
  return scheduleAsync.whenOrNull(
    data: (schedule) {
      final list = schedule[channelId];
      if (list == null) return null;
      for (final p in list) {
        if (p.isLive) return p;
      }
      return null;
    },
  );
});

/// Next programme for a given channel — powers the "Up Next" section in the player.
final upNextProvider = Provider.family<EpgProgramme?, String>((ref, channelId) {
  final scheduleAsync = ref.watch(epgScheduleProvider);
  return scheduleAsync.whenOrNull(
    data: (schedule) {
      final list = schedule[channelId];
      if (list == null) return null;
      EpgProgramme? current;
      for (final p in list) {
        if (p.isLive) {
          current = p;
          break;
        }
      }
      if (current == null) return list.firstOrNull;
      for (final p in list) {
        if (p.start.isAfter(current.end) ||
            p.start.isAtSameMomentAs(current.end)) {
          return p;
        }
      }
      return null;
    },
  );
});

/// Stream validation status map — updates progressively as cards become visible.
/// When a stream is confirmed dead, the [DeadChannelsNotifier] is notified
/// so the ID is persisted locally for admin review.
final streamStatusProvider =
    StateNotifierProvider<StreamStatusNotifier, Map<String, StreamStatus>>(
      (ref) => StreamStatusNotifier(
        onDead: (channelId) {
          ref.read(localDeadChannelsProvider.notifier).markDead(channelId);
        },
      ),
    );

/// Favorites provider for managing favorite channels.
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>(
  (ref) => FavoritesNotifier(),
);

/// Locally-detected dead channels — persisted to Hive for admin review.
final localDeadChannelsProvider =
    StateNotifierProvider<DeadChannelsNotifier, Set<String>>(
      (ref) => DeadChannelsNotifier(),
    );

/// Admin settings (GitHub PAT, repo owner/name) — persisted to Hive.
final adminSettingsProvider =
    StateNotifierProvider<AdminSettingsNotifier, Map<String, String>>(
      (ref) => AdminSettingsNotifier(),
    );

/// GitHub config service for fetching / pushing config.json.
final githubConfigServiceProvider = Provider<GithubConfigService>(
  (ref) => GithubConfigService(client: ref.watch(httpClientProvider)),
);

/// Remote config fetched from GitHub Pages on startup.
final remoteConfigProvider = FutureProvider<RemoteConfig>((ref) async {
  final service = ref.watch(githubConfigServiceProvider);
  return service.fetchConfig();
});

// ═══════════════════════════════════════════════════════════════════
// UI-FACING PROVIDERS (derived, cheap)
// ═══════════════════════════════════════════════════════════════════

/// Active category filter.
final activeCategoryProvider = StateProvider<String>((ref) => 'All');

/// Search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered channel list — recomputes when category or search changes.
///
/// Channels in the remote config's dead list are excluded.
/// Sorting priority: remote top channels > local favorites > alphabetical.
final filteredChannelsProvider = Provider<AsyncValue<List<Channel>>>((ref) {
  final channels = ref.watch(allChannelsProvider);
  final category = ref.watch(activeCategoryProvider);
  final query = ref.watch(searchQueryProvider);
  final favorites = ref.watch(favoritesProvider);
  final remoteConfig =
      ref.watch(remoteConfigProvider).valueOrNull ?? RemoteConfig.empty;

  return channels.whenData((list) {
    final filtered = list.where((c) {
      // Exclude channels flagged as dead by the remote config
      if (remoteConfig.deadChannels.contains(c.id)) return false;

      final matchesCategory = category == 'All' || c.category == category;
      final matchesSearch =
          query.isEmpty || c.name.toLowerCase().contains(query.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    // Sort: remote top > local favorites > alphabetical
    filtered.sort((a, b) {
      final aTop = remoteConfig.topChannels.contains(a.id);
      final bTop = remoteConfig.topChannels.contains(b.id);
      if (aTop && !bTop) return -1;
      if (!aTop && bTop) return 1;

      final aFav = favorites.contains(a.id);
      final bFav = favorites.contains(b.id);
      if (aFav && !bFav) return -1;
      if (!aFav && bFav) return 1;

      return a.name.compareTo(b.name);
    });

    return filtered;
  });
});

/// A provider to get the saved channels, split into live and offline.
final savedChannelsProvider = Provider<AsyncValue<Map<String, List<Channel>>>>((
  ref,
) {
  final channelsAsync = ref.watch(allChannelsProvider);
  final favorites = ref.watch(favoritesProvider);
  final scheduleAsync = ref.watch(epgScheduleProvider);

  return channelsAsync.whenData((channels) {
    final savedChannels = channels
        .where((c) => favorites.contains(c.id))
        .toList();
    final live = <Channel>[];
    final offline = <Channel>[];

    final schedule = scheduleAsync.valueOrNull ?? {};

    for (final channel in savedChannels) {
      final list = schedule[channel.tvgId];
      bool isLive = false;
      if (list != null) {
        for (final p in list) {
          if (p.isLive) {
            isLive = true;
            break;
          }
        }
      }
      if (isLive) {
        live.add(channel);
      } else {
        offline.add(channel);
      }
    }

    return {'live': live, 'offline': offline};
  });
});

/// A provider to find other channels currently playing the same program as the given channel.
final alsoShowingProvider = Provider.family<AsyncValue<List<Channel>>, String>((
  ref,
  channelId,
) {
  final channelsAsync = ref.watch(allChannelsProvider);
  final scheduleAsync = ref.watch(epgScheduleProvider);
  final nowPlaying = ref.watch(nowPlayingProvider(channelId));

  if (nowPlaying == null) {
    return const AsyncValue.data([]);
  }

  return channelsAsync.whenData((channels) {
    final schedule = scheduleAsync.valueOrNull ?? {};
    final matchingChannels = <Channel>[];

    for (final channel in channels) {
      if (channel.id == channelId) continue; // Skip current channel

      final list = schedule[channel.tvgId];
      if (list != null) {
        for (final p in list) {
          if (p.isLive &&
              p.title.toLowerCase() == nowPlaying.title.toLowerCase()) {
            matchingChannels.add(channel);
            break;
          }
        }
      }
    }

    return matchingChannels;
  });
});
