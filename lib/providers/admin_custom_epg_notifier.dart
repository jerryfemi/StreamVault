import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import '../data/models/remote_config.dart';

/// Persists the admin's custom EPG entries locally before pushing to GitHub.
class AdminCustomEpgNotifier extends StateNotifier<Map<String, CustomEpg>> {
  static const String _boxName = 'admin_custom_epg';
  late final Box<Map<dynamic, dynamic>> _box;

  AdminCustomEpgNotifier() : super({}) {
    _init();
  }

  void _init() {
    _box = Hive.box<Map<dynamic, dynamic>>(_boxName);
    final Map<String, CustomEpg> initial = {};
    for (final key in _box.keys.cast<String>()) {
      final value = _box.get(key);
      if (value != null) {
        try {
          initial[key] = CustomEpg.fromJson(Map<String, dynamic>.from(value));
        } catch (_) {}
      }
    }
    state = initial;
  }

  void setCustomEpg(String channelId, CustomEpg epg) {
    _box.put(channelId, epg.toJson());
    state = {...state, channelId: epg};
  }

  void removeCustomEpg(String channelId) {
    _box.delete(channelId);
    final newState = Map<String, CustomEpg>.from(state);
    newState.remove(channelId);
    state = newState;
  }
}

final adminCustomEpgProvider =
    StateNotifierProvider<AdminCustomEpgNotifier, Map<String, CustomEpg>>(
  (ref) => AdminCustomEpgNotifier(),
);
