import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../data/models/channel.dart';
import '../widgets/player/also_showing_section.dart';
import '../widgets/player/player_controls_overlay.dart';
import '../widgets/player/match_info_card.dart';
import '../widgets/player/up_next_section.dart';

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
  bool _isFullscreen = false;
  Timer? _controlsTimer;

  bool _isBuffering = false;
  bool _hasError = false;
  bool _noInternet = false;

  VideoTrack? _selectedVideoTrack;
  List<VideoTrack> _videoTracks = [];

  Channel? _channel;

  @override
  void initState() {
    super.initState();
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 32 * 1024 * 1024, // 32MB limit for reduced bandwidth
      ),
    );
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

    _player.stream.buffering.listen((buffering) {
      if (mounted) setState(() => _isBuffering = buffering);
    });
    _player.stream.error.listen((error) {
      debugPrint('Player error: $error');
      // Only show the fatal error overlay if the player is completely stopped
      // and not trying to recover/buffer. MPV often throws non-fatal warnings
      // for dropped HLS chunks while the video continues to play!
      if (mounted && !_player.state.playing && !_isBuffering) {
        setState(() {
          _hasError = true;
        });
      }
    });

    _player.stream.tracks.listen((tracks) {
      if (mounted) setState(() => _videoTracks = tracks.video);
    });
    _player.stream.track.listen((track) {
      if (mounted) setState(() => _selectedVideoTrack = track.video);
    });

    _startHideControlsTimer();
    _loadChannel();
  }

  Future<void> _loadChannel() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) setState(() => _noInternet = true);
      return;
    }

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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
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

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_noInternet) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, color: Colors.white54, size: 64),
              SizedBox(height: 16),
              Text(
                'No Internet Connection',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

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

    Widget playerArea = GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          // Video Surface
          Video(
            controller: _controller,
            controls: NoVideoControls, // We use custom overlays
          ),

          if (_isBuffering && !_hasError)
            const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),

          if (_hasError)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Color(0xFFFF7B7E),
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Stream Offline or Unavailable',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Custom Overlays
          if (!_hasError)
            PlayerControlsOverlay(
              showControls: _showControls,
              isPlaying: _isPlaying,
              position: _position,
              duration: _duration,
              onBack: () {
                if (_isFullscreen) {
                  _toggleFullscreen();
                } else {
                  Navigator.of(context).pop();
                }
              },
              onPlayPause: _togglePlayPause,
              onSeekOffset: _seek,
              onSeekTo: (newPos) => _player.seek(newPos),
              onInteraction: _resetControlsTimer,
              onToggleFullscreen: _toggleFullscreen,
              videoTracks: _videoTracks,
              selectedVideoTrack: _selectedVideoTrack,
              onSelectVideoTrack: (track) {
                _player.setVideoTrack(track);
              },
            ),

          if (_hasError && _showControls)
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  if (_isFullscreen) {
                    _toggleFullscreen();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
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
            ),
        ],
      ),
    );

    if (_isFullscreen) {
      return Scaffold(backgroundColor: Colors.black, body: playerArea);
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── VIDEO PLAYER AREA ──
              AspectRatio(aspectRatio: 16 / 9, child: playerArea),

              // ── MATCH INFO CARD ──
              MatchInfoCard(channel: _channel!, nowPlaying: nowPlaying),

              // ── ALSO SHOWING (Alternative Streams) ──
              if (nowPlaying != null)
                AlsoShowingSection(
                  currentTitle: nowPlaying.title,
                  currentId: _channel!.id,
                ),

              // ── UP NEXT ──
              if (upNext != null) UpNextSection(upNext: upNext),
            ],
          ),
        ),
      ),
    );
  }
}
