import 'package:flutter_test/flutter_test.dart';
import 'package:stream_vault/data/services/epg_service.dart';
import 'package:stream_vault/data/repositories/epg_repository.dart';

void main() {
  test('Debug EPG data flow end-to-end', () async {
    // ── Step 1: Fetch EPG using exact same EpgService the app uses ──
    print('=== STEP 1: EpgService.fetchSchedule() ===');
    final epgService = EpgService();
    
    Map<String, dynamic> schedule;
    try {
      schedule = await epgService.fetchSchedule();
      print('SUCCESS: fetchSchedule returned ${schedule.length} channels');
    } catch (e, stack) {
      print('FAILED: $e');
      print('Stack: $stack');
      return;
    }

    // ── Step 2: Print ALL schedule keys ──
    print('\n=== STEP 2: ALL EPG schedule keys ===');
    final keys = schedule.keys.toList()..sort();
    for (var i = 0; i < keys.length; i++) {
      final progs = schedule[keys[i]] as List;
      final liveCount = progs.where((p) => p.isLive).length;
      print('  [$i] "${keys[i]}" -> ${progs.length} programmes, $liveCount live now');
    }

    // ── Step 3: Use EpgRepository (same as app) ──
    print('\n=== STEP 3: EpgRepository.refresh() + getCurrent() ===');
    final epgRepo = EpgRepository(epgService);
    await epgRepo.refresh();

    // Test specific channels we know should match
    final testChannels = [
      'ASpor.tr@SD',
      'BandSports.br@SD',
      'beINSportsUSA.us@SD',
      'CanalPlusFoot.fr@SD',
      'ESPNDeportes.us@SD',
      'NBATV.us@SD',
      'SporTV.br@SD',
      // Also test without suffix
      'ASpor.tr',
      'BandSports.br',
    ];

    for (var id in testChannels) {
      final current = epgRepo.getCurrent(id);
      if (current != null) {
        print('  ✓ getCurrent("$id") -> "${current.title}" (${current.start} - ${current.end})');
      } else {
        print('  ✗ getCurrent("$id") -> null');
      }
    }

    // ── Step 4: Count total live programmes ──
    print('\n=== STEP 4: Summary ===');
    int totalLive = 0;
    for (var key in keys) {
      final progs = schedule[key] as List;
      if (progs.any((p) => p.isLive)) totalLive++;
    }
    print('Total EPG channels: ${keys.length}');
    print('Channels with LIVE programme right now: $totalLive');

  }, timeout: const Timeout(Duration(minutes: 5)));
}
