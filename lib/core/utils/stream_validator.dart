import 'dart:async';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../data/models/stream_status.dart';

class StreamValidator {
  static Future<StreamStatus> check(
    String url,
    Map<String, String> headers,
  ) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final client = http.Client();
      final responseFuture = client.send(request);

      final response = await responseFuture.timeout(
        AppConstants.validationTimeout,
      );

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';

      // Close connection immediately
      response.stream.listen((_) {}).cancel();
      client.close();

      if (response.statusCode != 200 && response.statusCode != 206) {
        return StreamStatus.dead;
      }

      // If the content type is HTML, it's likely a blocked or maintenance page, not a stream
      if (contentType.contains('text/html')) {
        return StreamStatus.dead;
      }

      return StreamStatus.live;
    } catch (_) {
      return StreamStatus.dead;
    }
  }
}
