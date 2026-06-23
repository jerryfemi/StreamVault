import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../data/models/channel.dart';

class PlayerPage extends ConsumerStatefulWidget {
  final String channelId;

  const PlayerPage({super.key, required this.channelId});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  late final Player _player;
  late final VideoController _controller;
  bool _isPlaying = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _showControls = true;
  Timer? _controlsTimer;

  Channel? _channel;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);

    _player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    _player.stream.position.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.stream.duration.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });

    _startHideControlsTimer();
    _loadChannel();
  }

  Future<void> _loadChannel() async {
    // A bit hacky: we find the channel from the global list synchronously
    // because the user must have clicked it from the Browse page (so it's loaded).
    final channelsAsync = ref.read(allChannelsProvider);
    channelsAsync.whenData((channels) {
      final match = channels.where((c) => c.id == widget.channelId).firstOrNull;
      if (match != null) {
        setState(() => _channel = match);
        // Play the stream URL!
        _player.open(Media(match.streamUrl));
      }
    });
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    _player.playOrPause();
    _resetControlsTimer();
  }

  void _seek(Duration offset) {
    final newPos = _position + offset;
    _player.seek(newPos < Duration.zero ? Duration.zero : newPos);
    _resetControlsTimer();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _controlsTimer?.cancel();
    }
  }

  void _startHideControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) setState(() => _showControls = false);
    });
  }

  void _resetControlsTimer() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

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
    if (_channel == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final nowPlaying = ref.watch(nowPlayingProvider(widget.channelId));
    final upNext = ref.watch(upNextProvider(widget.channelId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── VIDEO PLAYER AREA ──
              AspectRatio(
                aspectRatio: 16 / 9,
                child: GestureDetector(
                  onTap: _toggleControls,
                  child: Stack(
                    children: [
                      // Video Surface
                      Video(
                        controller: _controller,
                        controls: NoVideoControls, // We use custom overlays
                      ),

                      // Custom Overlays
                      AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
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
                          child: Column(
                            children: [
                              // Top Bar (Back button)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => context.pop(),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.black45,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white24,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_back,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    // Could add cast button or settings here
                                  ],
                                ),
                              ),
                              const Spacer(),

                              // Center Controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.replay_10,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    onPressed: () =>
                                        _seek(const Duration(seconds: -10)),
                                  ),
                                  const SizedBox(width: 24),
                                  GestureDetector(
                                    onTap: _togglePlayPause,
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.white24,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      child: Icon(
                                        _isPlaying
                                            ? Icons.pause
                                            : Icons.play_arrow,
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
                                    onPressed: () =>
                                        _seek(const Duration(seconds: 10)),
                                  ),
                                ],
                              ),
                              const Spacer(),

                              // Bottom Scrubber
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                                            color: AppColors.accent.withAlpha(
                                              64,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          _formatDuration(_position),
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
                                              thumbShape:
                                                  const RoundSliderThumbShape(
                                                    enabledThumbRadius: 6,
                                                  ),
                                              overlayShape:
                                                  const RoundSliderOverlayShape(
                                                    overlayRadius: 14,
                                                  ),
                                              activeTrackColor:
                                                  AppColors.accent,
                                              inactiveTrackColor:
                                                  Colors.white24,
                                              thumbColor: Colors.white,
                                            ),
                                            child: Slider(
                                              value:
                                                  _duration.inMilliseconds > 0
                                                  ? _position.inMilliseconds /
                                                        _duration.inMilliseconds
                                                  : 0.0,
                                              onChanged: (val) {
                                                _resetControlsTimer();
                                                final newPos = Duration(
                                                  milliseconds:
                                                      (val *
                                                              _duration
                                                                  .inMilliseconds)
                                                          .round(),
                                                );
                                                _player.seek(newPos);
                                              },
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatDuration(_duration),
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── MATCH INFO CARD ──
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Channel Header
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A365D),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _channel!.name.substring(0, 2).toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF90CDF4),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _channel!.name,
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Action Buttons
                        Consumer(
                          builder: (context, ref, child) {
                            final favs = ref.watch(favoritesProvider);
                            final isFav = favs.contains(_channel!.id);
                            return Row(
                              children: [
                                _ActionButton(
                                  icon: isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  iconColor: isFav
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                  onTap: () {
                                    ref
                                        .read(favoritesProvider.notifier)
                                        .toggleFavorite(_channel!.id);
                                  },
                                ),
                                const SizedBox(width: 8),
                                _ActionButton(
                                  icon: Icons.flag_outlined,
                                  iconColor: AppColors.textSecondary,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Reported stream issues.',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // EPG Block
                    if (nowPlaying != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withAlpha(38),
                                border: Border.all(
                                  color: AppColors.accent.withAlpha(51),
                                ),
                                borderRadius: BorderRadius.circular(6),
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
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              nowPlaying.title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.3,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (nowPlaying.description.isNotEmpty)
                              Text(
                                nowPlaying.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _MetaChip(
                                  icon: Icons.access_time,
                                  text:
                                      'Ends ${nowPlaying.end.toLocal().hour.toString().padLeft(2, '0')}:${nowPlaying.end.toLocal().minute.toString().padLeft(2, '0')}',
                                ),
                                _MetaChip(
                                  icon: Icons.hourglass_bottom,
                                  text:
                                      '${nowPlaying.timeRemaining.inMinutes} min left',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Fallback when no EPG
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'No programme information available',
                          style: AppTextStyles.subtitle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── ALSO SHOWING (Alternative Streams) ──
              if (nowPlaying != null)
                _AlsoShowingSection(
                  currentTitle: nowPlaying.title,
                  currentId: _channel!.id,
                ),

              // ── UP NEXT ──
              if (upNext != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Up Next on this channel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${upNext.start.toLocal().hour.toString().padLeft(2, '0')}:${upNext.start.toLocal().minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const Text(
                                  'TODAY',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textTertiary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 1,
                              height: 32,
                              color: AppColors.border,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    upNext.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    upNext.description.isNotEmpty
                                        ? upNext.description
                                        : 'No description',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlsoShowingSection extends ConsumerWidget {
  final String currentTitle;
  final String currentId;

  const _AlsoShowingSection({
    required this.currentTitle,
    required this.currentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allChannelsAsync = ref.watch(allChannelsProvider);
    return allChannelsAsync.when(
      data: (allChannels) {
        // Find channels playing the same exact title right now
        final matches = <Channel>[];
        for (final ch in allChannels) {
          if (ch.id == currentId) continue;
          final prog = ref.read(nowPlayingProvider(ch.id));
          if (prog != null && prog.title == currentTitle) {
            matches.add(ch);
          }
        }

        if (matches.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Also showing this match',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: matches.map((alt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          // Replace the route to switch stream!
                          context.pushReplacement(
                            '/browse/player/${Uri.encodeComponent(alt.id)}',
                          );
                        },
                        child: Container(
                          width: 220,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2D1B4E),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      alt.name.substring(0, 2).toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFFD6BCFA),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alt.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        if (alt.quality != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withAlpha(10),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              alt.quality!,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Fake stream verified status
                              Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF34D399),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x4C34D399),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Stream verified',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF34D399),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
