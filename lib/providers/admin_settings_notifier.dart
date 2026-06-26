import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

/// Persists admin-only settings (GitHub PAT, repo info) in a Hive box.
///
/// These are never shipped in the APK — the admin enters them once
/// on the device and they stay local.
class AdminSettingsNotifier extends StateNotifier<Map<String, String>> {
  static const String _boxName = 'admin_settings';
  static const String keyToken = 'github_token';
  static const String keyOwner = 'github_owner';
  static const String keyRepo = 'github_repo';

  late final Box<String> _box;

  AdminSettingsNotifier() : super({}) {
    _init();
  }

  void _init() {
    _box = Hive.box<String>(_boxName);
    state = {
      for (final key in _box.keys.cast<String>()) key: _box.get(key)!,
    };
  }

  String get token => state[keyToken] ?? '';
  String get owner => state[keyOwner] ?? 'jerryfemi';
  String get repo => state[keyRepo] ?? 'StreamVault-epg';

  void setToken(String value) => _put(keyToken, value);
  void setOwner(String value) => _put(keyOwner, value);
  void setRepo(String value) => _put(keyRepo, value);

  void _put(String key, String value) {
    _box.put(key, value);
    state = {...state, key: value};
  }
}
