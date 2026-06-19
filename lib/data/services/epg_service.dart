import 'dart:convert';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../models/epg_programme.dart';

/// Fetches and parses compressed XMLTV EPG data.
///
/// The heavy XML parsing runs on a background isolate via [Isolate.run]
/// to prevent frame drops on the main UI thread (EPG files are typically 10-50MB).
class EpgService {
  Future<Map<String, List<EpgProgramme>>> fetchSchedule() async {
    final response = await http.get(
      Uri.parse(AppConstants.epgUrl),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw NetworkException(
        'Failed to fetch EPG data: ${response.statusCode}',
      );
    }

    // The EPG file from epg.pw may come pre-decompressed by the HTTP client
    // depending on headers. We pass the raw body string to the isolate for parsing.
    // If the endpoint returns gzipped bytes, we'd decompress first with GZipCodec.
    final bodyString = utf8.decode(response.bodyBytes, allowMalformed: true);

    // Parse on a background isolate to avoid janking the UI thread
    return Isolate.run(() => _parseSchedule(bodyString));
  }
}

/// Parses XMLTV content into a channelId to programme list map.
///
/// Keeps a 24-hour forward window (now → +24h) so we can power both
/// "Now Playing" and "Up Next" features.
///
/// Must be a top-level function (not a closure) so it can be sent to an isolate.
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

  // Sort each channel's programmes chronologically so getNext() is a simple lookup
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
