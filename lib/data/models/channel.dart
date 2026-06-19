import 'package:hive_ce/hive.dart';
import 'raw_m3u_entry.dart';
import '../../core/utils/category_normalizer.dart';

part 'channel.g.dart';

@HiveType(typeId: 0)
class Channel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String logo;
  @HiveField(3)
  final String streamUrl;
  @HiveField(4)
  final String category;
  @HiveField(5)
  final String tvgId;
  @HiveField(6)
  final Map<String, String> headers;
  @HiveField(7)
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
