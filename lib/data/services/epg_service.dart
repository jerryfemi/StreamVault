import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../models/epg_programme.dart';

/// Fetches and parses compressed XMLTV EPG data.
///
/// Uses [compute] instead of [Isolate.run] for web compatibility.
/// Handles gzip decompression via the http library's built-in support
/// rather than dart:io's gzip codec (which is unavailable on web).
class EpgService {
  Future<Map<String, List<EpgProgramme>>> fetchSchedule() async {
    try {
      debugPrint('EpgService: Fetching EPG from ${AppConstants.epgUrl}...');
      final response = await http.get(
        Uri.parse(AppConstants.epgUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/xml, text/xml, */*',
        },
      ).timeout(const Duration(seconds: 120));

      debugPrint('EpgService: Response status code: ${response.statusCode}');
      if (response.statusCode != 200) {
        throw NetworkException(
          'Failed to fetch EPG data: ${response.statusCode}',
        );
      }

      String bodyString;
      final bytes = response.bodyBytes;
      debugPrint('EpgService: Received ${bytes.length} bytes');

      if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
        debugPrint('EpgService: Bytes have gzip magic header. Trying to decode...');
        bodyString = await _decompressGzip(bytes);
      } else {
        debugPrint('EpgService: Bytes do not have gzip magic header. Decoding as UTF8...');
        bodyString = utf8.decode(bytes, allowMalformed: true);
      }
      
      debugPrint('EpgService: XML string length: ${bodyString.length}');

      debugPrint('EpgService: First 100 chars: ${bodyString.substring(0, bodyString.length < 100 ? bodyString.length : 100)}');

      debugPrint('EpgService: Using compute to parse XML in background isolate...');
      final schedule = await compute(_parseSchedule, bodyString);

      debugPrint(
          'EpgService: Successfully parsed schedule for ${schedule.keys.length} channels.');
      return schedule;
    } catch (e, stack) {
      debugPrint('EpgService: Error during EPG fetch/parse: $e\n$stack');
      debugPrint('EpgService: Continuing with empty schedule.');
      return {};
    }
  }

  /// Decompresses gzip bytes. Uses dart:io on native platforms.
  Future<String> _decompressGzip(List<int> bytes) async {
    try {
      final decodedBytes = gzip.decode(bytes);
      return utf8.decode(decodedBytes, allowMalformed: true);
    } catch (e) {
      debugPrint('EpgService: Failed to decompress gzip: $e');
      return utf8.decode(bytes, allowMalformed: true);
    }
  }
}

/// Parses XMLTV content into a channelId to programme list map.
///
/// Keeps a 24-hour forward window (now → +24h) so we can power both
/// "Now Playing" and "Up Next" features.
///
/// Must be a top-level function so it can be sent to compute().
Map<String, List<EpgProgramme>> _parseSchedule(String xmlString) {
  final document = XmlDocument.parse(xmlString);

  final now = DateTime.now();
  final windowEnd = now.add(const Duration(hours: 24));
  final schedule = <String, List<EpgProgramme>>{};

  for (final node in document.findAllElements('programme')) {
    final startAttr = node.getAttribute('start');
    final stopAttr = node.getAttribute('stop');
    if (startAttr == null || stopAttr == null) continue;

    final start = _parseXmltvTime(startAttr);
    final end = _parseXmltvTime(stopAttr);

    // Only keep programmes within our 24-hour forward window
    if (end.isBefore(now) || start.isAfter(windowEnd)) continue;

    final channelId = node.getAttribute('channel') ?? '';
    if (channelId.isEmpty) continue;

    final programme = EpgProgramme(
      channelId: channelId,
      title: node.findElements('title').firstOrNull?.innerText ?? '',
      description: node.findElements('desc').firstOrNull?.innerText ?? '',
      start: start,
      end: end,
    );

    schedule.putIfAbsent(channelId, () => []).add(programme);
  }

  // Sort each channel's programmes chronologically
  for (final list in schedule.values) {
    list.sort((a, b) => a.start.compareTo(b.start));
  }

  return schedule;
}

/// Parses XMLTV timestamps like "20260619220000 +0000" into DateTime.
DateTime _parseXmltvTime(String raw) {
  final clean = raw.split(' ').first;
  if (clean.length < 14) return DateTime.now();

  return DateTime.parse(
    '${clean.substring(0, 4)}-${clean.substring(4, 6)}-${clean.substring(6, 8)}'
    'T${clean.substring(8, 10)}:${clean.substring(10, 12)}:${clean.substring(12, 14)}Z',
  );
}
