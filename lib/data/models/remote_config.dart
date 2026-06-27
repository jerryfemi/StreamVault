import 'dart:convert';

/// Data class representing the central config.json hosted on GitHub Pages.
///
/// Contains curated lists of dead and top (recommended) channel IDs,
/// pushed by the admin and consumed by all app instances.
class RemoteConfig {
  /// Channel IDs that are confirmed dead — hidden from all users.
  final Set<String> deadChannels;

  /// Channel IDs curated as top/recommended — sorted first for all users.
  final Set<String> topChannels;

  const RemoteConfig({
    this.deadChannels = const {},
    this.topChannels = const {},
  });

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    return RemoteConfig(
      deadChannels: (json['dead_channels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      topChannels: (json['top_channels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
    );
  }

  Map<String, dynamic> toJson() => {
        'dead_channels': deadChannels.toList()..sort(),
        'top_channels': topChannels.toList()..sort(),
      };

  String toJsonString() =>
      const JsonEncoder.withIndent('  ').convert(toJson());

  /// Empty config — used as a fallback when the remote fetch fails.
  static const RemoteConfig empty = RemoteConfig();
}
