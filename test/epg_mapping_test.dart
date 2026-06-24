import 'package:flutter_test/flutter_test.dart';
import 'package:stream_vault/data/services/m3u_service.dart';
import 'package:stream_vault/data/services/epg_service.dart';
import 'package:stream_vault/core/constants/app_constants.dart';


void main() {
  test('EPG Mapping Check', () async {
    final m3uService = M3uService();
    
    print('Fetching Sports M3U...');
    final sportsM3u = await m3uService.fetchCategory(AppConstants.sportsM3uUrl);
    print('Found ${sportsM3u.length} Sports channels.');
    
    print('Fetching Movies M3U...');
    final moviesM3u = await m3uService.fetchCategory(AppConstants.moviesM3uUrl);
    print('Found ${moviesM3u.length} Movies channels.');

    final allTvgIds = <String>{};
    for (var raw in [...sportsM3u, ...moviesM3u]) {
      final tvgId = raw.attributes['tvg-id'];
      if (tvgId != null && tvgId.isNotEmpty) {
        allTvgIds.add(tvgId);
      }
    }
    print('\nTotal unique tvg-ids from M3Us: ${allTvgIds.length}');

    print('\nFetching EPG Data from ${AppConstants.epgUrl} (This may take a minute due to file size)...');
    
    final epgService = EpgService();
    try {
      final schedule = await epgService.fetchSchedule();
      print('EPG fetch and parse complete. Found schedules for ${schedule.length} unique channels.');
      
      int matchCount = 0;
      int channelsWithLivePrograms = 0;
      
      for (var tvgId in allTvgIds) {
        if (schedule.containsKey(tvgId)) {
          matchCount++;
          final programs = schedule[tvgId]!;
          final liveProgram = programs.where((p) => p.isLive).firstOrNull;
          if (liveProgram != null) {
            channelsWithLivePrograms++;
            if (channelsWithLivePrograms <= 10) {
              print('MATCH (Live Now): $tvgId -> ${liveProgram.title} (${liveProgram.start.toLocal()} to ${liveProgram.end.toLocal()})');
            }
          }
        }
      }
      
      print('\n--- SUMMARY ---');
      print('Total M3U Channels (with tvg-id): ${allTvgIds.length}');
      print('Channels found in EPG: $matchCount');
      print('Channels currently airing a program right now: $channelsWithLivePrograms');
      print('-----------------');
      
    } catch (e) {
      print('EPG Fetch failed: $e');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
