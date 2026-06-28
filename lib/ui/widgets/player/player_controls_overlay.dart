import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../core/theme/app_theme.dart';

class PlayerControlsOverlay extends StatelessWidget {
  final bool showControls;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final Function(Duration) onSeekOffset;
  final Function(Duration) onSeekTo;
  final VoidCallback onInteraction;
  final VoidCallback onToggleFullscreen;
  final VideoTrack? selectedVideoTrack;
  final List<VideoTrack> videoTracks;
  final Function(VideoTrack)? onSelectVideoTrack;
  final VoidCallback? onEditEpg;

  const PlayerControlsOverlay({
    super.key,
    required this.showControls,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onBack,
    required this.onPlayPause,
    required this.onSeekOffset,
    required this.onSeekTo,
    required this.onInteraction,
    required this.onToggleFullscreen,
    this.selectedVideoTrack,
    this.videoTracks = const [],
    this.onSelectVideoTrack,
    this.onEditEpg,
  });

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final min = twoDigits(d.inMinutes.remainder(60));
    final sec = twoDigits(d.inSeconds.remainder(60));
    if (hours > 0) return '$hours:$min:$sec';
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black54,
              Colors.transparent,
              Colors.transparent,
              Colors.black87,
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Top Bar (Back button)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: onBack,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (onEditEpg != null)
                      GestureDetector(
                        onTap: onEditEpg,
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(
                            Icons.edit_calendar,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    if (videoTracks.length > 1)
                      PopupMenuButton<VideoTrack>(
                        initialValue: selectedVideoTrack,
                        onSelected: (track) {
                          onInteraction();
                          onSelectVideoTrack?.call(track);
                        },
                        onCanceled: onInteraction,
                        color: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        itemBuilder: (context) {
                          return videoTracks.map((track) {
                            String label = track.id == 'auto'
                                ? 'Auto'
                                : '${track.h ?? '?'}p';
                            return PopupMenuItem<VideoTrack>(
                              value: track,
                              child: Row(
                                children: [
                                  Icon(
                                    selectedVideoTrack == track
                                        ? Icons.check
                                        : null,
                                    color: AppColors.accent,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    label,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            );
                          }).toList();
                        },
                      ),
                  ],
                ),
              ),
            ),

            // Center Controls
            Positioned.fill(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.replay_10,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        onInteraction();
                        onSeekOffset(const Duration(seconds: -10));
                      },
                    ),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () {
                        onInteraction();
                        onPlayPause();
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      icon: const Icon(
                        Icons.forward_10,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        onInteraction();
                        onSeekOffset(const Duration(seconds: 10));
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Scrubber
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(64),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Color(0xFFFF7B7E),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            onInteraction();
                            onToggleFullscreen();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(
                              Icons.fullscreen,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          _formatDuration(position),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 14,
                              ),
                              activeTrackColor: AppColors.accent,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: (duration.inMilliseconds > 0
                                  ? position.inMilliseconds /
                                        duration.inMilliseconds
                                  : 0.0).clamp(0.0, 1.0),
                              onChanged: (val) {
                                onInteraction();
                                final newPos = Duration(
                                  milliseconds: (val * duration.inMilliseconds)
                                      .round(),
                                );
                                onSeekTo(newPos);
                              },
                            ),
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
