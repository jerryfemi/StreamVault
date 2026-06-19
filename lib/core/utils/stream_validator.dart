import 'package:http/http.dart' as http;
import '../../data/models/stream_status.dart';

class StreamValidator {
  static Future<StreamStatus> check(
    String url,
    Map<String, String> headers,
  ) async {
    try {
      final response = await http
          .head(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 7));

      return (response.statusCode == 200 || response.statusCode == 206)
          ? StreamStatus.live
          : StreamStatus.dead;
    } catch (_) {
      return StreamStatus.dead;
    }
  }
}
