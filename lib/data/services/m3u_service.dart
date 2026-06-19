import 'package:http/http.dart' as http;
import '../../core/errors/app_exceptions.dart';
import '../models/raw_m3u_entry.dart';

class M3uService {
  final http.Client _client;
  M3uService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<RawM3uEntry>> fetchCategory(String url) async {
    final response = await _client.get(
      Uri.parse(url),
      headers: {'Accept-Encoding': 'gzip'},  // iptv-org supports compression
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw NetworkException('Failed to fetch M3U: ${response.statusCode}');
    }

    return _parseM3u(response.body);
  }

  List<RawM3uEntry> _parseM3u(String content) {
    final entries = <RawM3uEntry>[];
    final lines = content.split('\n');

    for (var i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('#EXTINF')) continue;

      final streamUrl = lines[i + 1].trim();
      if (streamUrl.isEmpty || streamUrl.startsWith('#')) continue;

      entries.add(RawM3uEntry(
        attributes: _parseAttributes(line),
        title: _parseTitle(line),
        streamUrl: streamUrl,
      ));
    }
    return entries;
  }

  Map<String, String> _parseAttributes(String extinf) {
    // Regex extracts key="value" pairs from EXTINF line
    final pattern = RegExp(r'([\w-]+)="([^"]*)"');
    return Map.fromEntries(
      pattern.allMatches(extinf).map((m) => MapEntry(m.group(1)!, m.group(2)!)),
    );
  }

  String _parseTitle(String extinf) {
    final comma = extinf.lastIndexOf(',');
    return comma != -1 ? extinf.substring(comma + 1).trim() : 'Unknown';
  }
}
