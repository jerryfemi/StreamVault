# StreamVault — IPTV Streaming App
### Project Architecture & Implementation Plan

---

## What We're Building

A Flutter IPTV streaming app focused on **Sports** and **Movies** categories. It pulls from the iptv-org public catalogue, cross-references against their verified channel registry, enriches channels with live EPG (what's currently playing), validates streams in the background, and presents everything in a fast, clean, TV-grade UI.

**Core experience promise:** User opens the app → sees only working channels → sees what's currently playing on each one → taps and it plays. No dead links, no mystery streams, no buffering roulette.

---

## Guiding Principles

| Priority | Decision |
|---|---|
| **Lightweight** | Never re-fetch what hasn't changed. Cache aggressively at every layer. |
| **Speed** | Parallel async operations everywhere. UI never blocks on network. |
| **Reliability** | Only surface verified + validated channels. Dead links never reach the user. |
| **UX** | EPG-first design. User knows what's playing before they tap. |

---

## Project Folder Structure

```
streamvault/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart          # URLs, timeouts, cache durations
│   │   │   └── category_constants.dart     # Normalized category definitions
│   │   ├── errors/
│   │   │   └── app_exceptions.dart         # Typed exceptions (NetworkException, ParseException, StreamException)
│   │   └── utils/
│   │       ├── category_normalizer.dart    # "SPORTS" / "sport" / "Sports" → "Sports"
│   │       └── stream_validator.dart       # HEAD request validation logic
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── channel.dart                # Core channel model
│   │   │   ├── epg_programme.dart          # What's currently playing model
│   │   │   └── stream_status.dart          # Enum: live | dead | unknown | checking
│   │   │
│   │   ├── services/
│   │   │   ├── m3u_service.dart            # Fetches raw M3U from iptv-org
│   │   │   ├── registry_service.dart       # Fetches channels.json and streams.json
│   │   │   └── epg_service.dart            # Fetches + parses XMLTV EPG data
│   │   │
│   │   ├── repositories/
│   │   │   ├── channel_repository.dart     # Orchestrates M3U + registry cross-ref
│   │   │   └── epg_repository.dart         # Manages EPG fetch, parse, and lookup
│   │   │
│   │   └── local/
│   │       ├── cache_manager.dart          # Hive box read/write abstraction
│   │       └── hive_adapters/
│   │           ├── channel_adapter.dart    # Hive TypeAdapter for Channel
│   │           └── epg_adapter.dart        # Hive TypeAdapter for EpgProgramme
│   │
│   ├── providers/
│   │   ├── channel_provider.dart           # FutureProvider: verified channel list
│   │   ├── epg_provider.dart               # FutureProvider: EPG data map
│   │   ├── stream_status_provider.dart     # StateNotifierProvider: live/dead map
│   │   ├── category_provider.dart          # Derived provider: active category filter
│   │   ├── search_provider.dart            # StateProvider: search query string
│   │   └── favourites_provider.dart        # NotifierProvider: persisted favourites
│   │
│   └── ui/
│       ├── screens/
│       │   ├── splash_screen.dart          # Init + cache warm-up
│       │   ├── home_screen.dart            # Shell with bottom nav
│       │   ├── dashboard_screen.dart       # Category pills + channel grid
│       │   ├── player_screen.dart          # Video player + metadata + alternatives
│       │   └── favourites_screen.dart      # Saved channels
│       │
│       ├── widgets/
│       │   ├── channel_card.dart           # Grid card: logo + name + EPG + status dot
│       │   ├── epg_badge.dart              # "🔴 LIVE: Champions League" pill
│       │   ├── category_pill.dart          # Horizontal filter tab
│       │   ├── stream_status_dot.dart      # Green/red/grey indicator
│       │   ├── player_overlay.dart         # Auto-dimming play controls
│       │   └── alternatives_strip.dart     # "Also showing" horizontal list
│       │
│       └── theme/
│           ├── app_theme.dart              # Dark theme, colors, text styles
│           └── app_colors.dart             # Named color palette
│
├── test/
│   ├── data/
│   │   ├── m3u_service_test.dart
│   │   ├── registry_service_test.dart
│   │   └── channel_repository_test.dart
│   └── providers/
│       └── channel_provider_test.dart
│
└── pubspec.yaml
```

---

## Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.5.1       # State management + caching
  media_kit: ^1.1.10             # Video player (better_player replacement — actively maintained)
  media_kit_video: ^1.2.4        # Video widget for media_kit
  media_kit_libs_video: ^1.0.4   # Native codec support
  http: ^1.2.1                   # Network requests
  hive_flutter: ^1.1.0           # Local cache (structured, fast, no SQL overhead)
  xml: ^6.5.0                    # XMLTV EPG parsing
  cached_network_image: ^3.3.1   # Channel logo loading with cache
  visibility_detector: ^0.4.0+2  # Lazy stream validation — only validate visible cards
  go_router: ^13.2.0             # Navigation

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.9
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
```

**Why these choices:**
- `media_kit` over `better_player` — better_player is unmaintained, media_kit has active development and proper HLS support
- `hive_flutter` over SharedPreferences — we're caching structured objects (channel lists, EPG), not key-value strings. Hive handles this with TypeAdapters and is significantly faster
- `xml` package for XMLTV — EPG data is always XML, this is the standard Dart parser

---

## Data Sources & What Each Does

```
SOURCE 1: iptv-org M3U (per category)
  URL: https://iptv-org.github.io/iptv/categories/sports.m3u
  URL: https://iptv-org.github.io/iptv/categories/movies.m3u
  Gives us: stream URLs, channel names, logos, tvg-id, group-title
  Cache: 6 hours (they update daily, but 6hr is safe for session freshness)

SOURCE 2: iptv-org channels.json (verified registry)
  URL: https://iptv-org.github.io/api/channels.json
  Gives us: verified channel IDs, official names, broadcast countries, is_nsfw flag
  Cache: 24 hours (this changes rarely)
  Role: QUALITY GATE — only channels whose tvg-id exists here are shown to user

SOURCE 3: EPG XML feed
  Primary: https://epg.pw/xmltv/epg_EN.xml.gz  (compressed, English language)
  Gives us: programme titles, descriptions, start/end times, per channel tvg-id
  Cache: 1 hour (programme data changes as shows start/end)
  Role: Powers the "what's currently on" display on every channel card

SOURCE 4: iptv-org streams.json (stream metadata & headers)
  URL: https://iptv-org.github.io/api/streams.json
  Gives us: stream URLs, channel IDs, user_agent, referrer, quality
  Cache: 24 hours
  Role: HEADER & QUALITY RESOLVER — provides per-channel headers (User-Agent, Referer) and quality metadata to ensure stream validation and playback succeed.
```

---

## Phase 1 — Verified Channel Pipeline

This is the foundation. Nothing else works without this being solid.

### Step 1.1 — Category Normalizer (`core/utils/category_normalizer.dart`)

The iptv-org M3U data is messy. The same category appears as "Sports", "SPORTS", "sport", "Sport/Football". Before anything else, normalize all category strings.

```dart
class CategoryNormalizer {
  static const _map = {
    'sport': 'Sports',
    'sports': 'Sports',
    'football': 'Sports',
    'soccer': 'Sports',
    'movie': 'Movies',
    'movies': 'Movies',
    'films': 'Movies',
    'cinema': 'Movies',
    // extend as needed
  };

  static String normalize(String raw) {
    return _map[raw.trim().toLowerCase()] ?? raw.trim();
  }
}
```

**Why this matters:** Without this, your category filter pills will show "Sports", "SPORTS", and "sport" as three separate tabs, fragmenting your channel list.

---

### Step 1.2 — M3U Service (`data/services/m3u_service.dart`)

Fetches raw M3U text. Parses it manually (no third-party parser — they're fragile with iptv-org's format quirks).

```dart
class M3uService {
  final http.Client _client;
  M3uService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<RawM3uEntry>> fetchCategory(String url) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: {'Accept-Encoding': 'gzip'},  // iptv-org supports compression
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw NetworkException('Failed to fetch M3U: ${response.statusCode}');
    }

    return _parseM3u(response.body);
  }

  List<RawM3uEntry> _parseM3u(String content) {
    final entries = <RawM3uEntry>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('#EXTINF')) continue;

      final streamUrl = lines[i + 1].trim();
      if (streamUrl.isEmpty || streamUrl.startsWith('#')) continue;

      entries.add(RawM3uEntry(
        attributes: _parseAttributes(line),
        title: _parseTitle(line),
        streamUrl: streamUrl,
      ));
    }
    return entries;
  }

  Map<String, String> _parseAttributes(String extinf) {
    // Regex extracts key="value" pairs from EXTINF line
    final pattern = RegExp(r'([\w-]+)="([^"]*)"');
    return Map.fromEntries(
      pattern.allMatches(extinf).map((m) => MapEntry(m.group(1)!, m.group(2)!)),
    );
  }

  String _parseTitle(String extinf) {
    final comma = extinf.lastIndexOf(',');
    return comma != -1 ? extinf.substring(comma + 1).trim() : 'Unknown';
  }
}
```

**Why custom parsing:** The M3U format is simple (EXTINF line → stream URL line). Writing 40 lines of your own parser beats taking on a pub.dev dependency that might not handle edge cases in iptv-org's specific formatting.

---

### Step 1.3 — Registry Service (`data/services/registry_service.dart`)

Fetches the verified channel registry and stream-specific metadata (User-Agent, Referer, Quality).

```dart
class StreamMetadata {
  final String channelId;
  final Map<String, String> headers;
  final String? quality;

  StreamMetadata({
    required this.channelId,
    required this.headers,
    this.quality,
  });
}

class RegistryService {
  final http.Client _client;
  RegistryService({http.Client? client}) : _client = client ?? http.Client();

  Future<Set<String>> fetchVerifiedIds() async {
    final response = await _client.get(
      Uri.parse('https://iptv-org.github.io/api/channels.json'),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw NetworkException('Failed to fetch verified IDs: ${response.statusCode}');
    }

    final List<dynamic> json = jsonDecode(response.body);

    // We only need the IDs — extract them into a Set for O(1) lookup
    return json
        .map((c) => c['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<Map<String, StreamMetadata>> fetchStreamMetadata() async {
    final response = await _client.get(
      Uri.parse('https://iptv-org.github.io/api/streams.json'),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw NetworkException('Failed to fetch streams metadata: ${response.statusCode}');
    }

    final List<dynamic> json = jsonDecode(response.body);
    final metadataMap = <String, StreamMetadata>{}; // Keyed by stream URL

    for (final item in json) {
      final streamUrl = item['url']?.toString();
      if (streamUrl == null || streamUrl.isEmpty) continue;

      final headers = <String, String>{};
      if (item['user_agent'] != null) {
        headers['User-Agent'] = item['user_agent'].toString();
      }
      if (item['referrer'] != null) {
        headers['Referer'] = item['referrer'].toString();
      }

      metadataMap[streamUrl] = StreamMetadata(
        channelId: item['channel']?.toString() ?? '',
        headers: headers,
        quality: item['quality']?.toString(),
      );
    }
    return metadataMap;
  }
}
```

**Why a Set:** When cross-referencing, you'll do thousands of `contains()` lookups. `Set<String>` is O(1) vs `List<String>` O(n). With 10,000+ channels in the registry this matters.

### Channel Model (`data/models/channel.dart`)

The core domain model, merging raw M3U data with streams.json metadata.

```dart
class Channel {
  final String id;
  final String name;
  final String logo;
  final String streamUrl;
  final String category;
  final String tvgId;
  final Map<String, String> headers;
  final String? quality;

  const Channel({
    required this.id,
    required this.name,
    required this.logo,
    required this.streamUrl,
    required this.category,
    required this.tvgId,
    this.headers = const {},
    this.quality,
  });

  factory Channel.fromRaw(RawM3uEntry raw, {Map<String, String> headers = const {}, String? quality}) {
    return Channel(
      id: raw.attributes['tvg-id'] ?? '',
      name: raw.title,
      logo: raw.attributes['tvg-logo'] ?? '',
      streamUrl: raw.streamUrl,
      category: CategoryNormalizer.normalize(raw.attributes['group-title'] ?? 'Other'),
      tvgId: raw.attributes['tvg-id'] ?? '',
      headers: headers,
      quality: quality,
    );
  }
}
```

---

### Step 1.4 — Channel Repository (`data/repositories/channel_repository.dart`)

This is where the M3U data, registry, and stream metadata merge. Only verified channels come out the other end, populated with their per-stream headers and quality.

```dart
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
    final allEntries = results.sublist(2)
        .expand((list) => list as List<RawM3uEntry>)
        .toList();

    final channels = allEntries
        .map((e) {
          final tvgId = e.attributes['tvg-id'] ?? '';
          final meta = streamMetadataMap[e.streamUrl]; // Exact match by URL
          return Channel.fromRaw(
            e,
            headers: meta?.headers ?? const {},
            quality: meta?.quality,
          );
        })
        .where((c) =>
            c.streamUrl.isNotEmpty &&
            c.tvgId.isNotEmpty &&
            verifiedIds.contains(c.tvgId))  // THE QUALITY GATE
        .toList();

    await _cache.saveChannels(channels);
    return channels;
  }
}
```

**Key decision:** `Future.wait` fetches sports M3U, movies M3U, channels.json registry, and streams.json metadata all at the same time in parallel. This halves startup time and ensures we have all metadata ready on channels creation.

---

## Phase 2 — Stream Validation

Even verified channels can have dead streams on a given day. We validate without blocking the UI — and we validate **lazily**, only for what's actually visible, not the entire catalogue at once.

### Why not batch-validate everything upfront

Validating all 500+ channels on app open seems straightforward but doesn't scale well: it drains battery, burns cellular data, and risks tripping rate limits on the source servers — all for channels the user may never scroll to. Instead, validation is driven by what's actually on screen.

### Stream Status Model

```dart
enum StreamStatus { unknown, checking, live, dead }

// Provider holds a map of channelId → StreamStatus
// Updated progressively as channels enter the viewport
```

### Lazy Viewport-Driven Validation

```yaml
dependencies:
  visibility_detector: ^0.4.0+2
```

Each channel card wraps itself in a `VisibilityDetector`. Only when a card is more than 50% visible does it trigger a validation check — and only once per session per channel.

```dart
VisibilityDetector(
  key: Key('channel_${channel.id}'),
  onVisibilityChanged: (info) {
    if (info.visibleFraction > 0.5) {
      ref.read(streamStatusProvider.notifier).validateIfUnknown(channel);
    }
  },
  child: ChannelCard(channel: channel),
)
```

This means a user who only ever browses Sports never triggers a single validation request for Movies. Data and battery usage scale with actual usage, not catalogue size.

### Validation Logic with Per-Channel Headers

A common gotcha with public IPTV streams: many block generic HTTP client signatures (like Dart's default user agent) or require specific Referer/Referrer headers to play. We resolve this by using the `headers` field from the channel (cross-referenced from `streams.json`), ensuring our verification checks mimic real client requests.

```dart
class StreamValidator {
  static Future<StreamStatus> check(String url, Map<String, String> headers) async {
    try {
      final response = await http.head(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 7));

      return (response.statusCode == 200 || response.statusCode == 206)
          ? StreamStatus.live
          : StreamStatus.dead;
    } catch (_) {
      return StreamStatus.dead;
    }
  }
}
```

And the same headers travel with the player itself:

```dart
final media = Media(channel.streamUrl, httpHeaders: channel.headers);
```

**UX behaviour:**
- Channel cards render immediately with a grey "unknown" dot
- Validation fires only as cards scroll into view
- Dots update to green (live) or red (dead) as results come in
- Dead channels are NOT hidden — they stay visible but visually dimmed (`.ch-card.dead { opacity: 0.35; }` in the dashboard design) with an "Unavailable" label
- User can still tap a dead channel and gets a clean "Stream offline — Tap to retry" screen, not a crash

**Why not hide dead channels:** Hiding them makes the grid jump around as validation runs. Dimming them is less jarring and more honest — and it's already how the dashboard design renders the Fox Sports 1 card.

---

## Phase 3 — EPG Integration

This is what makes the app feel premium. XMLTV files don't just contain "what's on now" — they contain a full forward schedule, typically 24-48 hours ahead. We keep a window of programmes per channel (not just the current one), so we can show both "now playing" and "up next" — which the player design calls for directly.

### EPG Programme Model (`data/models/epg_programme.dart`)

```dart
@immutable
class EpgProgramme {
  final String channelId;      // matches tvg-id
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;

  bool get isLive {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  double get progressPercent {
    final total = end.difference(start).inSeconds;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Duration get timeRemaining => end.difference(DateTime.now());
}
```

### EPG Repository (`data/repositories/epg_repository.dart`)

Holds a **schedule window** per channel (now → +24h), not just the current slice. This is what powers both the progress bar on dashboard cards and the "Up Next" section in the player.

```dart
class EpgRepository {
  final EpgService _service;
  Map<String, List<EpgProgramme>> _schedule = {};

  EpgRepository(this._service);

  Future<void> refresh() async {
    _schedule = await _service.fetchSchedule();
  }

  EpgProgramme? getCurrent(String channelId) {
    final list = _schedule[channelId] ?? [];
    return list.firstWhereOrNull((p) => p.isLive);
  }

  EpgProgramme? getNext(String channelId) {
    final list = _schedule[channelId] ?? [];
    final current = getCurrent(channelId);
    if (current == null) return list.firstOrNull;
    return list.firstWhereOrNull((p) => p.start.isAfter(current.end));
  }
}
```

### EPG Service (`data/services/epg_service.dart`)

EPG data comes as gzipped XMLTV format, often 10-50MB raw. Parsing that much XML on the main UI thread causes visible frame drops — so the heavy lifting is offloaded to a background isolate via `compute()`. Only the parsed, finalized map crosses back to the main thread.

```dart
class EpgService {
  Future<Map<String, List<EpgProgramme>>> fetchSchedule() async {
    final response = await http.get(Uri.parse(AppConstants.epgUrl));
    final decompressed = GZipDecoder().decodeBytes(response.bodyBytes);

    // Parsing runs on a separate isolate — main thread stays responsive
    return compute(_parseScheduleInBackground, decompressed);
  }
}

// Must be top-level (or static) for compute() to use it across isolates
Map<String, List<EpgProgramme>> _parseScheduleInBackground(List<int> bytes) {
  final xmlString = utf8.decode(bytes);
  final document = XmlDocument.parse(xmlString);

  final now = DateTime.now();
  final windowEnd = now.add(const Duration(hours: 24));
  final schedule = <String, List<EpgProgramme>>{};

  for (final node in document.findAllElements('programme')) {
    final start = _parseXmltvTime(node.getAttribute('start')!);
    final end = _parseXmltvTime(node.getAttribute('stop')!);

    // Keep a forward window, not just "currently airing" —
    // this is what makes "Up Next" possible
    if (end.isBefore(now) || start.isAfter(windowEnd)) continue;

    final channelId = node.getAttribute('channel') ?? '';
    final programme = EpgProgramme(
      channelId: channelId,
      title: node.findElements('title').firstOrNull?.innerText ?? '',
      description: node.findElements('desc').firstOrNull?.innerText ?? '',
      start: start,
      end: end,
    );

    schedule.putIfAbsent(channelId, () => []).add(programme);
  }

  // Sort each channel's programmes chronologically so getNext() is a simple lookup
  for (final list in schedule.values) {
    list.sort((a, b) => a.start.compareTo(b.start));
  }

  return schedule;
}

DateTime _parseXmltvTime(String raw) {
  // XMLTV format: 20260619220000 +0000
  final clean = raw.split(' ').first;
  return DateTime.parse(
    '${clean.substring(0, 4)}-${clean.substring(4, 6)}-${clean.substring(6, 8)}'
    'T${clean.substring(8, 10)}:${clean.substring(10, 12)}:${clean.substring(12, 14)}Z',
  );
}
```

**Performance note:** Keeping a 24-hour forward window (instead of just the current slice) means a slightly larger in-memory map — typically 3-8MB instead of under 1MB — but it's what makes the "Up Next" feature in the player screen possible. Still in-memory only, still cleared and re-fetched hourly, never written to disk.

---

## Phase 4 — Riverpod Provider Layer

All providers compose cleanly. UI talks only to providers, never to services or repositories directly.

```dart
// === INFRASTRUCTURE PROVIDERS ===
final httpClientProvider = Provider((ref) => http.Client());
final cacheManagerProvider = Provider((ref) => CacheManager());

// === SERVICE PROVIDERS ===
final m3uServiceProvider = Provider((ref) => M3uService(client: ref.watch(httpClientProvider)));
final registryServiceProvider = Provider((ref) => RegistryService(client: ref.watch(httpClientProvider)));
final epgServiceProvider = Provider((ref) => EpgService());

// === REPOSITORY PROVIDERS ===
final channelRepoProvider = Provider((ref) => ChannelRepository(
  ref.watch(m3uServiceProvider),
  ref.watch(registryServiceProvider),
  ref.watch(cacheManagerProvider),
));

final epgRepoProvider = Provider((ref) => EpgRepository(ref.watch(epgServiceProvider)));

// === DATA PROVIDERS ===

// All verified channels (Sports + Movies combined)
final allChannelsProvider = FutureProvider<List<Channel>>((ref) async {
  return ref.watch(channelRepoProvider).getChannels([
    AppConstants.sportsM3uUrl,
    AppConstants.moviesM3uUrl,
  ]);
});

// EPG schedule — refreshes every hour, holds a 24h forward window per channel
final epgScheduleProvider = FutureProvider<void>((ref) async {
  await ref.watch(epgRepoProvider).refresh();
});

// Current programme for a given channel — what's playing right now
final nowPlayingProvider = Provider.family<EpgProgramme?, String>((ref, channelId) {
  ref.watch(epgScheduleProvider);
  return ref.watch(epgRepoProvider).getCurrent(channelId);
});

// Next programme for a given channel — powers the "Up Next" section in the player
final upNextProvider = Provider.family<EpgProgramme?, String>((ref, channelId) {
  ref.watch(epgScheduleProvider);
  return ref.watch(epgRepoProvider).getNext(channelId);
});

// Stream validation status map — updates progressively as cards become visible
final streamStatusProvider = StateNotifierProvider<StreamStatusNotifier, Map<String, StreamStatus>>(
  (ref) => StreamStatusNotifier(),
);

// === UI-FACING PROVIDERS (derived, cheap) ===

// Active category filter
final activeCategoryProvider = StateProvider<String>((ref) => 'Sports');

// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered channel list — recomputes when category or search changes
final filteredChannelsProvider = Provider<AsyncValue<List<Channel>>>((ref) {
  final channels = ref.watch(allChannelsProvider);
  final category = ref.watch(activeCategoryProvider);
  final query = ref.watch(searchQueryProvider);

  return channels.whenData((list) => list.where((c) {
    final matchesCategory = c.category == category;
    final matchesSearch = query.isEmpty || c.matchesSearch(query);
    return matchesCategory && matchesSearch;
  }).toList());
});

// "Also showing" — channels in same category currently playing same programme title
final alsoShowingProvider = Provider.family<List<Channel>, Channel>((ref, current) {
  final channels = ref.watch(allChannelsProvider).valueOrNull ?? [];
  final epgRepo = ref.watch(epgRepoProvider);
  ref.watch(epgScheduleProvider);

  final currentProgramme = epgRepo.getCurrent(current.tvgId);
  if (currentProgramme == null) return [];

  return channels.where((c) {
    if (c.tvgId == current.tvgId) return false;
    if (c.category != current.category) return false;
    final programme = epgRepo.getCurrent(c.tvgId);
    return programme?.title.toLowerCase() == currentProgramme.title.toLowerCase();
  }).toList();
});

// Favourites
final favouritesProvider = NotifierProvider<FavouritesNotifier, Set<String>>(
  FavouritesNotifier.new,
);
```

---

## Phase 5 — Caching Layer (`data/local/cache_manager.dart`)

```
What we cache         │ Storage  │ TTL
──────────────────────┼──────────┼──────────────
Channel list          │ Hive     │ 6 hours
Registry IDs          │ Hive     │ 24 hours
EPG schedule (24h fwd)│ Memory   │ 1 hour (re-fetch)
Stream status map     │ Memory   │ Session only
Recently watched      │ Hive     │ Permanent (capped at 8)
Favourites            │ Hive     │ Permanent
Channel logos         │ File     │ 7 days (cached_network_image, capped at 300)
```

**Why EPG in memory only:** Even with the 24h forward window (needed for "Up Next"), this data is only valid for the next 24 hours and shifts constantly. Persisting it to disk and reading it back next session would still require a fresh fetch to stay accurate — so there's no benefit to writing it out, only added I/O.

**Why stream status in memory only:** Dead/live status of a stream can flip between sessions. Never persist it.

**Updated size estimate:** The EPG forward window pushes memory usage from under 1MB up to roughly 3-8MB while loaded — still memory-only, still cleared hourly, and disk footprint is unaffected. Total app disk usage stays in the same 4-7MB range discussed earlier.

---

## Phase 6 — UI Design

The visual direction is already locked in via your HTML mockups (`splash.html`, `dashboard.html`, `player.html`). These confirm and extend the original plan — here's how the architecture maps onto them.

### Confirmed visual language

**Colour palette** (matches your mockups exactly):
- Background: `#0A0A0C`
- Surface: `#141418` / elevated `#1C1C22` / hover `#222228`
- Accent (live/sports): `#E5383B`
- Live green: `#34D399`
- Text: primary `#F0F0F2`, secondary `#7A7A86`, tertiary `#4A4A54`
- Border: `rgba(255,255,255,0.06)`

This is a refinement of the original plan's palette — the mockups add a proper elevation system (surface → surface-elevated → surface-hover) which the original draft didn't have. Worth carrying that 3-tier surface system into the Flutter `ThemeData`.

### Splash Screen (`splash.html` → `screens/splash_screen.dart`)

Your design adds a **step-by-step load tracker** that the original plan didn't have:

```
✓ Fetching channel registry
✓ Cross-referencing verified IDs
⟳ Loading EPG data…
○ Validating streams
```

This maps directly onto the actual pipeline phases, which is good — it's not decorative, it's literally showing the real init sequence:

```dart
enum InitStep { registry, crossReference, epg, validation }

class SplashController extends StateNotifier<InitStep> {
  Future<void> runInitSequence(WidgetRef ref) async {
    state = InitStep.registry;
    await ref.read(registryServiceProvider).fetchVerifiedIds();

    state = InitStep.crossReference;
    await ref.read(allChannelsProvider.future);

    state = InitStep.epg;
    await ref.read(epgScheduleProvider.future);

    state = InitStep.validation;
    // Validation itself is lazy/viewport-driven (Phase 2), so this step
    // just marks "ready" — actual validation continues on dashboard scroll
  }
}
```

One adjustment: since stream validation is lazy (Phase 2 decision), the "Validating streams" step on splash should resolve almost immediately rather than waiting on real HEAD requests — it's marking readiness to *start* validating, not validating everything upfront. Don't block splash exit on this step.

**Warm-start fast path:** On a cold start (first install, or cache expired), all four steps genuinely take time and the tracker is useful. On a warm start — channel list and EPG already cached and still within TTL — the whole sequence can resolve in well under 200ms, too fast for the steps to be readable. Two options:

- Enforce a minimum splash duration (~600ms) so the steps don't flash illegibly, or
- Skip the step tracker entirely on warm cache and go straight to the dashboard, only showing the full sequence on cold start

The second is the better experience for repeat users — they shouldn't watch a fake-feeling progress animation every time they reopen an app that already has fresh data sitting in Hive.

### Dashboard Screen (`dashboard.html` → `screens/dashboard_screen.dart`)

Your design is richer than the original plan's simple grid — it has five distinct sections, each backed by a specific provider:

```
┌─────────────────────────────────┐
│  StreamVault          🔍 🔔     │  ← Header + search + notifications
│  ┌───────────────────────────┐ │
│  │   FEATURED MATCH (hero)    │ │  ← featuredMatchProvider
│  │   Team A  2-1  Team B 67'  │ │
│  │   [Watch Live]              │ │
│  └───────────────────────────┘ │
│                                 │
│  🔴 Live Now                    │  ← liveNowProvider (sorted by EPG live + validated)
│  [card] [card] [card]          │
│                                 │
│  🏆 Sports          24 ch →     │  ← filteredChannelsProvider('Sports')
│  [card] [card] [card]          │
│                                 │
│  🎬 Movies          56 ch →     │  ← filteredChannelsProvider('Movies')
│  [poster][poster][poster]      │
│                                 │
│  🕐 Recently Watched             │  ← recentlyWatchedProvider (Hive-backed)
│  [pill] [pill] [pill]          │
└─────────────────────────────────┘
```

**New provider needed — Featured Match**

The hero card needs a provider that doesn't exist in the original plan. It picks the single most prominent live sports programme to feature:

```dart
final featuredMatchProvider = Provider<Channel?>((ref) {
  final channels = ref.watch(allChannelsProvider).valueOrNull ?? [];
  final epgRepo = ref.watch(epgRepoProvider);
  ref.watch(epgScheduleProvider);
  final statusMap = ref.watch(streamStatusProvider);

  // Only consider Sports channels that are validated live and currently airing something
  final candidates = channels.where((c) {
    if (c.category != 'Sports') return false;
    if (statusMap[c.id] != StreamStatus.live) return false;
    return epgRepo.getCurrent(c.tvgId) != null;
  }).toList();

  if (candidates.isEmpty) return null;

  // Simple v1 heuristic: prioritize known major broadcasters first,
  // otherwise take the first valid live match found
  return candidates.first;
});
```

**New provider needed — Recently Watched**

```dart
final recentlyWatchedProvider = NotifierProvider<RecentlyWatchedNotifier, List<String>>(
  RecentlyWatchedNotifier.new,
);

class RecentlyWatchedNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => []; // loaded from Hive on init

  void recordWatch(String channelId) {
    state = [channelId, ...state.where((id) => id != channelId)].take(8).toList();
    // persist to Hive — capped at 8 entries, negligible storage
  }
}
```

**Channel card states** — your mockup defines three states directly in CSS that the providers need to feed:

| Visual state | CSS class | Provider source |
|---|---|---|
| Live, has EPG | `.ch-dot.live` + `.ch-epg` block with progress bar | `streamStatusProvider` + `nowPlayingProvider` |
| Live, no EPG | `.ch-dot.live`, no EPG block | `streamStatusProvider` only |
| Unknown (not yet validated) | `.ch-dot.unknown` | Default state before viewport triggers validation |
| Dead | `.ch-card.dead` (35% opacity) + `.ch-unavail` "Unavailable" label | `streamStatusProvider` returns `dead` |

The EPG progress bar (`.ch-epg-fill` width %) maps directly to `EpgProgramme.progressPercent` from Phase 3.

**Movies render differently** — your design uses poster cards with genre pills and a play overlay, not the same card as Sports. This is a deliberate split:

```dart
// Sports → ChannelCard (compact, EPG-progress-focused)
// Movies → MoviePosterCard (poster art, genre pill, "Started Xm ago / Starting at" copy)
```

Worth adding a `genre` field to the `Channel` model, sourced from the `group-title` M3U attribute when available, defaulting to a generic label when absent.

### Player Screen (`player.html` → `screens/player_screen.dart`)

Your design confirms the original plan's player layout and adds the EPG-driven sections we just discussed:

```
┌─────────────────────────────────┐
│         VIDEO PLAYER            │  ← media_kit, 16:9, overlay controls
├─────────────────────────────────┤
│  Match info / channel metadata  │
├─────────────────────────────────┤
│  Also showing this match        │  ← alsoShowingProvider
│  [BT Sport] [SuperSport] [beIN] │     each card shows quality + verified status
├─────────────────────────────────┤
│  Up Next on this channel        │  ← upNextProvider(channel.tvgId)
│  22:30  Post-Match Analysis     │
│         In-depth analysis...    │
└─────────────────────────────────┘
```

This is exactly why the Phase 3 EPG fix (keeping a 24h forward window instead of just "currently airing") was necessary — without it, the "Up Next" section in your design would have no data source. It's now fully backed by `upNextProvider`.

The "Also showing" alt-cards include a quality label (`1080p · 50fps`) which is cross-referenced from `streams.json`.

### Sort order across all sections

- **Live Now strip**: validated live + has current EPG programme, sorted by soonest-ending first (creates urgency, matches "catch it before it ends")
- **Category grids (Sports/Movies)**: validated live with EPG → validated live without EPG → unknown → dead (always last)
- **Recently Watched**: most recent first, capped at 8

---

## Implementation Order

Build in this sequence — each milestone is independently usable:

```
Week 1  │ M3U fetch + registry cross-ref + channel model
        │ Milestone: Can print a list of verified channels to console

Week 1  │ Hive caching + category normalizer
        │ Milestone: Second app open loads from cache instantly

Week 2  │ Riverpod providers (channels, filter, search)
        │ Milestone: UI can consume channel data with loading/error states

Week 2  │ Dashboard UI — Sports + Movies grids (no EPG, no validation yet)
        │ Milestone: Browsable grid of verified channels, matches dashboard.html static layout

Week 3  │ Lazy stream validation (viewport-triggered, per-channel headers)
        │ Milestone: Live/dead dots appear on cards as you scroll

Week 3  │ media_kit player + player screen
        │ Milestone: Tap card → stream plays, basic metadata shown

Week 4  │ EPG integration (compute()-isolate parsing, 24h schedule window)
        │ Milestone: "Now playing" + progress bars appear on cards, "Up Next" appears in player

Week 4  │ Featured match hero, Recently Watched, "Also showing", Favourites
        │ Milestone: Full v1 feature complete — matches all three HTML mockups end to end
```

---

## Key Technical Decisions Summary

| Decision | Choice | Reason |
|---|---|---|
| Video player | `media_kit` | better_player is unmaintained |
| Local storage | `hive_flutter` | Structured objects, faster than SharedPreferences |
| M3U parsing | Custom | iptv-org quirks break third-party parsers |
| Quality gate | channels.json cross-ref | Filters ~40% dead/unofficial streams automatically |
| EPG | XMLTV via epg.pw | Industry standard, best coverage for English channels |
| EPG window | 24h forward, not just current | Required for "Up Next" — current-only would have no future data |
| EPG parsing | `compute()` isolate | 10-50MB XML parse would jank the UI thread otherwise |
| Stream validation | Lazy, viewport-triggered | Validating 500+ channels upfront wastes battery/data for content never viewed |
| Stream headers | Per-channel headers from streams.json | Sourcing user-agent/referrer dynamically resolves connection issues for blocked streams |
| Parallel fetching | `Future.wait` | Halves startup time vs sequential fetching |
| EPG memory | In-memory only | Stale on next session anyway — no point persisting |
| Category filter | Normalizer util | Raw M3U category strings are inconsistent |

---

## Phase 9 — Future Scaling (Not v1)

Not needed for a portfolio project distributed to a handful of friends — flagged here so it's not forgotten if the app ever grows beyond that.

**The risk:** Every install hits iptv-org's GitHub Pages and epg.pw directly for M3U, registry, and EPG data. At low volume (you + friends) this is genuinely fine — negligible load on public infrastructure. At higher volume (hundreds+ concurrent users, all re-fetching the same files repeatedly), this starts to look like an unintentional DDoS against free public resources, and if those sources start rate-limiting or change CORS policy, the app breaks for everyone simultaneously with no client-side fix possible.

**The fix, if it's ever needed:**

```
App → Cloudflare Worker (cache + stale-while-revalidate) → iptv-org / epg.pw
```

A Worker with KV storage fetches the M3U/registry/EPG data on a schedule (e.g. once per hour) and serves all app users from that cached copy. This turns potentially thousands of client requests into one upstream request per refresh interval, and gives you a layer to add your own rate-limiting, response shaping, or fallback sources later.

This is roughly a day of work and deliberately out of scope until there's a real signal it's needed — building it now would be solving a problem you don't have yet.

---

## What This Is Not

- Not a general-purpose IPTV player (user brings their own M3U) — that's a different product
- Not a backend service — everything is client-side against public APIs
- Not scraping anything — all data sources are publicly published by iptv-org

---

*StreamVault Project Plan v1.0*
