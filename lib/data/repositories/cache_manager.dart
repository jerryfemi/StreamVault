import 'package:hive_ce/hive.dart';
import '../models/channel.dart';

class CacheManager {
  static const String _boxName = 'channels_cache';

  Future<void> init() async {
    Hive.registerAdapter(ChannelAdapter());
    await Hive.openBox<Channel>(_boxName);
    await Hive.openBox<String>('favorites_cache');
    // Clear stale cache from previous runs with broken quality gate
    await clearCache();
  }

  Future<void> clearCache() async {
    final box = Hive.box<Channel>(_boxName);
    await box.clear();
  }

  Future<List<Channel>?> getChannels() async {
    final box = Hive.box<Channel>(_boxName);
    if (box.isEmpty) return null;
    return box.values.toList();
  }

  Future<void> saveChannels(List<Channel> channels) async {
    final box = Hive.box<Channel>(_boxName);
    await box.clear(); // Clear old cache
    await box.addAll(channels);
  }
}
