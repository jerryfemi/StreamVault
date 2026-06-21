import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

class FavoritesNotifier extends StateNotifier<Set<String>> {
  static const String _boxName = 'favorites_cache';
  late final Box<String> _box;

  FavoritesNotifier() : super(<String>{}) {
    _init();
  }

  void _init() {
    _box = Hive.box<String>(_boxName);
    state = _box.values.toSet();
  }

  void toggleFavorite(String channelId) {
    if (state.contains(channelId)) {
      _box.delete(channelId);
      state = {...state}..remove(channelId);
    } else {
      _box.put(channelId, channelId);
      state = {...state, channelId};
    }
  }

  bool isFavorite(String channelId) {
    return state.contains(channelId);
  }
}
