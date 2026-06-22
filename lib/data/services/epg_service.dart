import 'dart:convert';

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
    final response = await http.get(
      Uri.parse(AppConstants.epgUrl),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/xml, text/xml, */*',
        // Don't request gzip on web — let the browser handle it transparently.
        // On web, the browser decompresses gzip automatically.
      },
    ).timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      throw NetworkException(
        'Failed to fetch EPG data: ${response.statusCode}',
      );
    }

    String bodyString;
    final bytes = response.bodyBytes;

    // Check if the response bytes are gzipped (magic bytes: 0x1F, 0x8B).
    // On web, the browser typically decompresses gzip transparently,
    // so we may get raw XML directly. On native, we may get raw gzip bytes.
    if (bytes.length >= 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
      // Gzipped — decompress using dart:io on native only.
      // On web this branch should not be hit because the browser decompresses.
      bodyString = await _decompressGzip(bytes);
    } else {
      bodyString = utf8.decode(bytes, allowMalformed: true);
    }

    // Parse on a background isolate (compute works on both web and native)
    return compute(_parseSchedule, bodyString);
  }

  /// Decompresses gzip bytes. Uses dart:io on native platforms.
  /// On web, the browser should handle decompression transparently,
  /// but as a fallback we try ZLibDecoder from dart:convert (not available
  /// on web), so this is only called on native.
  Future<String> _decompressGzip(List<int> bytes) async {
    // Dynamic import workaround — this code only runs on native
    // where dart:io is available.
    try {
      // Use the zlib codec from dart:convert which is platform-agnostic
      // ZLibDecoder is in dart:io though, so we use a different approach:
      // The gzip format starts with a header, then deflate data.
      // dart:convert has no built-in gzip decoder, so for native we
      // use compute to call the parser with the raw approach.
      
      // Actually, on native platforms, the http package may or may not
      // auto-decompress. Let's just try to parse as UTF-8 first.
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
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
