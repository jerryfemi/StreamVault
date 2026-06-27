import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/remote_config.dart';

/// Service for fetching the remote config.json and pushing updates
/// to GitHub via the Contents API.
class GithubConfigService {
  final http.Client _client;

  GithubConfigService({required http.Client client}) : _client = client;

  // ── Fetch ──────────────────────────────────────────────────────────

  /// Downloads and parses the remote config.json.
  /// Returns [RemoteConfig.empty] on any failure.
  Future<RemoteConfig> fetchConfig() async {
    try {
      final uri = Uri.parse(AppConstants.remoteConfigUrl).replace(
        queryParameters: {'t': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      final response = await _client
          .get(uri)
          .timeout(AppConstants.defaultTimeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return RemoteConfig.fromJson(json);
      }
    } catch (e) {
      debugPrint('[GithubConfigService] fetch failed: $e');
    }
    return RemoteConfig.empty;
  }

  // ── Push ────────────────────────────────────────────────────────────

  /// Pushes an updated config.json to the GitHub repo via the Contents API.
  ///
  /// [token]  — GitHub Personal Access Token with `repo` scope.
  /// [owner]  — e.g. "jerryfemi"
  /// [repo]   — e.g. "StreamVault-epg"
  /// [path]   — file path in the repo, e.g. "config.json"
  /// [config] — the new config to write.
  ///
  /// Returns `true` on success.
  Future<bool> pushConfig({
    required String token,
    required String owner,
    required String repo,
    required String path,
    required RemoteConfig config,
    String? commitMessage,
  }) async {
    final apiUrl =
        'https://api.github.com/repos/$owner/$repo/contents/$path';
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    };

    try {
      // 1. Get current file SHA (required for updates, absent for creation).
      String? sha;
      final getResp = await _client
          .get(Uri.parse(apiUrl), headers: headers)
          .timeout(AppConstants.defaultTimeout);

      if (getResp.statusCode == 200) {
        final body = jsonDecode(getResp.body) as Map<String, dynamic>;
        sha = body['sha'] as String?;
      }

      // 2. PUT the updated file content.
      final content = base64Encode(utf8.encode(config.toJsonString()));
      final payload = <String, dynamic>{
        'message': commitMessage ?? 'Update config.json via StreamVault admin',
        'content': content,
        // ignore: use_null_aware_elements
        if (sha != null) 'sha': sha,
      };

      final putResp = await _client
          .put(
            Uri.parse(apiUrl),
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(AppConstants.defaultTimeout);

      if (putResp.statusCode == 200 || putResp.statusCode == 201) {
        debugPrint('[GithubConfigService] push success');
        return true;
      } else {
        debugPrint(
            '[GithubConfigService] push failed: ${putResp.statusCode} ${putResp.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[GithubConfigService] push error: $e');
      return false;
    }
  }
}
