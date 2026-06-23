import 'package:flutter_test/flutter_test.dart';

import 'package:stream_vault/core/constants/app_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// Fetch with retries to handle flaky connections.
Future<http.Response> fetchWithRetry(String url, {int retries = 3}) async {
  for (var i = 0; i < retries; i++) {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0',
              'Accept-Encoding': 'gzip, deflate, br',
            },
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) return response;
    } catch (e) {
      print('  Attempt ${i + 1} failed: $e');
      if (i < retries - 1) {
        await Future.delayed(Duration(seconds: 2 * (i + 1)));
      }
    }
  }
  throw Exception('All $retries attempts failed for $url');
}

void main() {
  test(
    'Full EPG match check for Sports channels',
    () async {
      // 1. Fetch Sports M3U with retries
      print('=== Fetching Sports M3U ===');
      final m3uResponse = await fetchWithRetry(AppConstants.sportsM3uUrl);
      final m3uBody = m3uResponse.body;

      // Parse M3U manually to extract tvg-ids
      final lines = m3uBody.split('\n');
      final tvgIds = <String>{};
      final tvgIdRegex = RegExp(r'tvg-id="([^"]*)"');

      for (var line in lines) {
        if (line.startsWith('#EXTINF')) {
          final match = tvgIdRegex.firstMatch(line);
          if (match != null && match.group(1)!.isNotEmpty) {
            tvgIds.add(match.group(1)!);
          }
        }
      }
      print(
        'Total Sports entries: ${lines.where((l) => l.startsWith("#EXTINF")).length}',
      );
      print('Unique tvg-ids: ${tvgIds.length}');

      // Print first 10 tvg-ids for inspection
      print('\n=== Sample tvg-ids (first 10) ===');
      for (var id in tvgIds.take(10)) {
        print('  tvg-id: "$id"');
      }

      // 2. Fetch EPG with retries
      print('\n=== Fetching EPG from ${AppConstants.epgUrl} ===');
      final epgResponse = await fetchWithRetry(AppConstants.epgUrl);
      final bytes = epgResponse.bodyBytes;

      String xmlString;
      if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
        xmlString = utf8.decode(gzip.decode(bytes), allowMalformed: true);
      } else {
        xmlString = utf8.decode(bytes, allowMalformed: true);
      }

      // Parse EPG channel IDs from XML
      final channelRegex = RegExp(r'<programme[^>]*channel="([^"]*)"');
      final epgChannelIds = <String>{};
      for (var match in channelRegex.allMatches(xmlString)) {
        epgChannelIds.add(match.group(1)!);
      }
      print('EPG unique channel IDs: ${epgChannelIds.length}');

      // Print first 20 EPG channel IDs
      print('\n=== Sample EPG channel IDs (first 20) ===');
      final sortedEpgIds = epgChannelIds.toList()..sort();
      for (var i = 0; i < sortedEpgIds.length && i < 20; i++) {
        print('  EPG channel: "${sortedEpgIds[i]}"');
      }

      // 3. Compare
      print('\n=== Matching Sports tvg-ids against EPG ===');
      int exactMatch = 0;
      int baseMatch = 0;
      int noMatch = 0;

      for (var rawId in tvgIds) {
        final baseId = rawId.split('@').first;

        if (epgChannelIds.contains(rawId)) {
          exactMatch++;
          print('  ✓ EXACT: "$rawId"');
        } else if (epgChannelIds.contains(baseId)) {
          baseMatch++;
          print('  ✓ BASE:  "$rawId" matched as "$baseId"');
        } else {
          noMatch++;
          print('  ✗ NONE:  "$rawId" (base: "$baseId")');
        }
      }

      print('\n--- SUMMARY ---');
      print('Exact match (raw tvg-id in EPG): $exactMatch');
      print('Base match (stripped @ suffix):   $baseMatch');
      print('No match at all:                  $noMatch');
      print('Total unique Sports tvg-ids:      ${tvgIds.length}');
      print('Total EPG channel IDs:            ${epgChannelIds.length}');
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
