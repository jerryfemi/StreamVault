import 'package:flutter_test/flutter_test.dart';
import 'package:stream_vault/core/constants/app_constants.dart';
import 'package:stream_vault/core/utils/category_normalizer.dart';
import 'package:stream_vault/data/services/m3u_service.dart';
import 'package:stream_vault/data/services/epg_service.dart';

void main() {
  group('Category Normalizer Tests', () {
    test('Should normalize variations of sports and movies', () {
      expect(CategoryNormalizer.normalize('sport'), 'Sports');
      expect(CategoryNormalizer.normalize('SPORTS'), 'Sports');
      expect(CategoryNormalizer.normalize('movies'), 'Movies');
      expect(CategoryNormalizer.normalize('Action'), 'Action'); // unknown stays same
    });
  });

  group('M3U Service Live Tests', () {
    final service = M3uService();

    test('Fetch and print Sports channels', () async {
      print('--- Fetching Sports M3U: ${AppConstants.sportsM3uUrl} ---');
      final channels = await service.fetchCategory(AppConstants.sportsM3uUrl);
      print('Found ${channels.length} sports channels.');
      print('First 10 sports channels:');
      for (var i = 0; i < channels.length && i < 10; i++) {
        print('  - ${channels[i].title} (${channels[i].attributes['tvg-id']})');
      }
      expect(channels, isNotEmpty);
    });

    test('Fetch and print Movies channels', () async {
      print('--- Fetching Movies M3U: ${AppConstants.moviesM3uUrl} ---');
      final channels = await service.fetchCategory(AppConstants.moviesM3uUrl);
      print('Found ${channels.length} movies channels.');
      print('First 10 movies channels:');
      for (var i = 0; i < channels.length && i < 10; i++) {
        print('  - ${channels[i].title} (${channels[i].attributes['tvg-id']})');
      }
      expect(channels, isNotEmpty);
    });
  });

  group('EPG Service Live Parse Test', () {
    final epgService = EpgService();

    test('Fetch and parse EPG from Matt Huisman NZ Freeview', () async {
      print('--- Fetching EPG schedule from: ${AppConstants.epgUrl} ---');
      final schedule = await epgService.fetchSchedule();
      print('EPG schedule loaded. Total channels with EPG: ${schedule.length}');
      
      final firstChannelId = schedule.keys.firstOrNull;
      if (firstChannelId != null) {
        print('Sample EPG channel: $firstChannelId');
        final programs = schedule[firstChannelId] ?? [];
        print('Programs found: ${programs.length}');
        for (var i = 0; i < programs.length && i < 3; i++) {
          final p = programs[i];
          print('  - Title: ${p.title}');
          print('    Desc: ${p.description}');
          print('    Start: ${p.start} | End: ${p.end}');
        }
      }
      expect(schedule, isNotEmpty);
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}
