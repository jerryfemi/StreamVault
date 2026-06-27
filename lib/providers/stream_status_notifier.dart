import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/stream_validator.dart';
import '../../data/models/stream_status.dart';

/// Manages the validation state of all streams in memory (session-scoped).
///
/// Each channel is validated at most once per session. Validation is triggered
/// lazily by VisibilityDetector when a channel card scrolls into the viewport.
///
/// An optional [onDead] callback is invoked when a channel is confirmed dead,
/// allowing the provider layer to persist the ID to the local dead-channels store.
class StreamStatusNotifier extends StateNotifier<Map<String, StreamStatus>> {
  final void Function(String channelId)? onDead;

  StreamStatusNotifier({this.onDead}) : super({});

  /// Validates a channel's stream if it hasn't been checked this session.
  ///
  /// Does nothing if the channel is already checked or currently checking.
  Future<void> validateIfUnknown(
    String channelId,
    String streamUrl,
    Map<String, String> headers,
  ) async {
    // Skip if already validated or currently validating
    if (state.containsKey(channelId)) return;

    // Mark as checking
    state = {...state, channelId: StreamStatus.checking};

    // Perform the GET request with per-channel headers
    final result = await StreamValidator.check(streamUrl, headers);

    // Update with the result
    state = {...state, channelId: result};

    // Notify the persistent dead-channels store
    if (result == StreamStatus.dead) {
      onDead?.call(channelId);
    }
  }
}
