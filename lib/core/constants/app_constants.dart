/// App-wide constants for URLs, cache durations, and timeouts.
class AppConstants {
  AppConstants._();

  // ── M3U category URLs ──
  static const String sportsM3uUrl =
      'https://iptv-org.github.io/iptv/categories/sports.m3u';
  static const String moviesM3uUrl =
      'https://iptv-org.github.io/iptv/categories/movies.m3u';

  // ── EPG ──
  static const String epgUrl = 'https://jerryfemi.github.io/StreamVault-epg/guide.xml.gz';

  // ── Cache TTLs ──
  static const Duration channelCacheTtl = Duration(hours: 6);
  static const Duration registryCacheTtl = Duration(hours: 24);
  static const Duration epgRefreshInterval = Duration(hours: 1);

  // ── Network timeouts ──
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration registryTimeout = Duration(seconds: 20);
  static const Duration validationTimeout = Duration(seconds: 7);
}
