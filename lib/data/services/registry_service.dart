import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/errors/app_exceptions.dart';

class StreamMetadata {
  final String channelId;
  final Map<String, String> headers;
  final String? quality;

  StreamMetadata({
    required this.channelId,
    required this.headers,
    this.quality,
  });
}

class RegistryService {
  final http.Client _client;
  RegistryService({http.Client? client}) : _client = client ?? http.Client();

  Future<Set<String>> fetchVerifiedIds() async {
    final response = await _client.get(
      Uri.parse('https://iptv-org.github.io/api/channels.json'),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw NetworkException('Failed to fetch verified IDs: ${response.statusCode}');
    }

    final List<dynamic> json = jsonDecode(response.body);

    // We only need the IDs — extract them into a Set for O(1) lookup
    return json
        .map((c) => c['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<Map<String, StreamMetadata>> fetchStreamMetadata() async {
    final response = await _client.get(
      Uri.parse('https://iptv-org.github.io/api/streams.json'),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw NetworkException('Failed to fetch streams metadata: ${response.statusCode}');
    }

    final List<dynamic> json = jsonDecode(response.body);
    final metadataMap = <String, StreamMetadata>{}; // Keyed by stream URL

    for (final item in json) {
      final streamUrl = item['url']?.toString();
      if (streamUrl == null || streamUrl.isEmpty) continue;

      final headers = <String, String>{};
      if (item['user_agent'] != null) {
        headers['User-Agent'] = item['user_agent'].toString();
      }
      if (item['referrer'] != null) {
        headers['Referer'] = item['referrer'].toString();
      }

      metadataMap[streamUrl] = StreamMetadata(
        channelId: item['channel']?.toString() ?? '',
        headers: headers,
        quality: item['quality']?.toString(),
      );
    }
    return metadataMap;
  }
}
