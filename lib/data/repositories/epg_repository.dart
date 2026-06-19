import '../models/epg_programme.dart';
import '../services/epg_service.dart';

/// Manages EPG data in memory.
///
/// Holds a 24-hour schedule window per channel. Provides queries for
/// the current programme and the next upcoming programme.
class EpgRepository {
  final EpgService _service;
  Map<String, List<EpgProgramme>> _schedule = {};

  EpgRepository(this._service);

  /// Fetches and replaces the in-memory schedule.
  Future<void> refresh() async {
    _schedule = await _service.fetchSchedule();
  }

  /// Returns the currently airing programme for a channel, or null.
  EpgProgramme? getCurrent(String channelId) {
    final list = _schedule[channelId];
    if (list == null) return null;

    for (final p in list) {
      if (p.isLive) return p;
    }
    return null;
  }

  /// Returns the next scheduled programme after the current one, or null.
  EpgProgramme? getNext(String channelId) {
    final list = _schedule[channelId];
    if (list == null) return null;

    final current = getCurrent(channelId);
    if (current == null) return list.firstOrNull;

    for (final p in list) {
      if (p.start.isAfter(current.end) || p.start.isAtSameMomentAs(current.end)) {
        return p;
      }
    }
    return null;
  }
}
