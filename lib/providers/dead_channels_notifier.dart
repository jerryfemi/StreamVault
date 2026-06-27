import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

/// Manages locally-detected dead channel IDs, persisted to a Hive box.
///
/// As the stream validator marks channels dead during scrolling,
/// their IDs accumulate here for the admin to review and push.
class DeadChannelsNotifier extends StateNotifier<Set<String>> {
  static const String _boxName = 'local_dead_channels';
  late final Box<String> _box;

  DeadChannelsNotifier() : super(<String>{}) {
    _init();
  }

  void _init() {
    _box = Hive.box<String>(_boxName);
    state = _box.values.toSet();
  }

  /// Mark a channel as dead (persisted).
  void markDead(String channelId) {
    if (state.contains(channelId)) return;
    _box.put(channelId, channelId);
    state = {...state, channelId};
  }

  /// Remove a channel from the dead list (e.g. it came back to life).
  void markAlive(String channelId) {
    if (!state.contains(channelId)) return;
    _box.delete(channelId);
    state = {...state}..remove(channelId);
  }

  /// Clear all locally tracked dead channels.
  void clearAll() {
    _box.clear();
    state = {};
  }

  bool isDead(String channelId) => state.contains(channelId);
}
