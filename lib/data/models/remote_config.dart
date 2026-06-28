import 'dart:convert';

class CustomEpg {
  final String title;
  final DateTime start;
  final DateTime end;
  final String description;

  const CustomEpg({
    required this.title,
    required this.start,
    required this.end,
    this.description = '',
  });

  factory CustomEpg.fromJson(Map<String, dynamic> json) {
    return CustomEpg(
      title: json['title'] as String,
      start: DateTime.parse(json['start'] as String).toLocal(),
      end: DateTime.parse(json['end'] as String).toLocal(),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'description': description,
      };
}

/// Data class representing the central config.json hosted on GitHub Pages.
///
/// Contains curated lists of dead and top (recommended) channel IDs,
/// pushed by the admin and consumed by all app instances.
class RemoteConfig {
  /// Channel IDs that are confirmed dead — hidden from all users.
  final Set<String> deadChannels;

  /// Channel IDs curated as top/recommended — sorted first for all users.
  final Set<String> topChannels;

  /// Custom EPG entries set by the admin for specific channels.
  final Map<String, CustomEpg> customEpg;

  const RemoteConfig({
    this.deadChannels = const {},
    this.topChannels = const {},
    this.customEpg = const {},
  });

  factory RemoteConfig.fromJson(Map<String, dynamic> json) {
    final Map<String, CustomEpg> customEpgMap = {};
    if (json['custom_epg'] != null) {
      final map = json['custom_epg'] as Map<String, dynamic>;
      map.forEach((key, value) {
        customEpgMap[key] = CustomEpg.fromJson(value as Map<String, dynamic>);
      });
    }

    return RemoteConfig(
      deadChannels: (json['dead_channels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      topChannels: (json['top_channels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          {},
      customEpg: customEpgMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'dead_channels': deadChannels.toList()..sort(),
        'top_channels': topChannels.toList()..sort(),
        'custom_epg': customEpg.map((k, v) => MapEntry(k, v.toJson())),
      };

  String toJsonString() =>
      const JsonEncoder.withIndent('  ').convert(toJson());

  /// Empty config — used as a fallback when the remote fetch fails.
  static const RemoteConfig empty = RemoteConfig();
}
