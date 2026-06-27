import 'package:hive_ce/hive.dart';
import '../models/channel.dart';

class CacheManager {
  static const String _boxName = 'channels_cache';

  Future<void> init() async {
    Hive.registerAdapter(ChannelAdapter());
    await Hive.openBox<Channel>(_boxName);
    await Hive.openBox<String>('favorites_cache');
    await Hive.openBox<String>('local_dead_channels');
    await Hive.openBox<String>('admin_settings');
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
    await box.clear();
    await box.addAll(channels);
  }
}
