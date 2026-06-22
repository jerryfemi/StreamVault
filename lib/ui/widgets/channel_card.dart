import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/channel.dart';
import '../../data/models/epg_programme.dart';
import '../../data/models/stream_status.dart';
import '../../providers/providers.dart';

/// A single channel card matching the Browse-page grid design.
///
/// Shows: logo → channel name → stream status dot → EPG "Now Playing"
/// with a live progress bar, or graceful fallbacks for no-EPG / dead states.
class ChannelCard extends ConsumerWidget {
  final Channel channel;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ChannelCard({
    super.key,
    required this.channel,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status =
        ref.watch(streamStatusProvider)[channel.id] ?? StreamStatus.unknown;
    final nowPlaying = ref.watch(nowPlayingProvider(channel.tvgId));
    final isFav = ref.watch(favoritesProvider).contains(channel.id);
    final isDead = status == StreamStatus.dead;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedOpacity(
        opacity: isDead ? 0.35 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Top row: Logo + status dot ──
              _buildTopRow(status, isFav, ref),
              const SizedBox(height: 10),

              // ── Channel name ──
              Text(
                channel.name,
                style: AppTextStyles.channelName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // ── Bottom section: EPG or fallback ──
              if (isDead)
                _buildUnavailable()
              else if (nowPlaying != null)
                _buildEpgBlock(nowPlaying)
              else
                _buildNoEpg(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow(StreamStatus status, bool isFav, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Channel logo
        _ChannelLogo(channel: channel),
        // Status dot + favorite
        Column(
          children: [
            _StatusDot(status: status),
            if (isFav) ...[
              const SizedBox(height: 4),
              const Icon(Icons.favorite, color: AppColors.accent, size: 12),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEpgBlock(EpgProgramme programme) {
    final remaining = programme.timeRemaining;
    final timeText = _formatTimeRemaining(remaining);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: Color(0x14E5383B), // accent 8%
        border: Border(left: BorderSide(color: AppColors.accent, width: 2)),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with pulsing dot
          Row(
            children: [
              const _PulsingDot(),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  programme.title,
                  style: AppTextStyles.epgTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1),
                  child: LinearProgressIndicator(
                    value: programme.progressPercent,
                    minHeight: 2,
                    backgroundColor: const Color(0x0FFFFFFF),
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(timeText, style: AppTextStyles.epgTime),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoEpg() {
    return Text(
      'No programme info',
      style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic),
    );
  }

  Widget _buildUnavailable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Unavailable',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  String _formatTimeRemaining(Duration d) {
    if (d.isNegative) return '0m';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }
}

/// Generates a deterministic color pair from the channel name for the logo.
class _ChannelLogo extends StatelessWidget {
  final Channel channel;
  const _ChannelLogo({required this.channel});

  @override
  Widget build(BuildContext context) {
    final colors = _logoColors(channel.name);
    final abbrev = _abbreviation(channel.name);

    if (channel.logo.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.logo),
        child: Image.network(
          channel.logo,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackLogo(abbrev, colors),
        ),
      );
    }
    return _fallbackLogo(abbrev, colors);
  }

  Widget _fallbackLogo(String abbrev, (Color, Color) colors) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(AppRadii.logo),
      ),
      alignment: Alignment.center,
      child: Text(
        abbrev,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: colors.$2,
        ),
      ),
    );
  }

  String _abbreviation(String name) {
    final words = name.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.length >= 3
        ? name.substring(0, 3).toUpperCase()
        : name.toUpperCase();
  }

  (Color, Color) _logoColors(String name) {
    final hash = name.hashCode.abs();
    final hue = (hash % 360).toDouble();
    final bg = HSLColor.fromAHSL(1.0, hue, 0.35, 0.18).toColor();
    final fg = HSLColor.fromAHSL(1.0, hue, 0.55, 0.72).toColor();
    return (bg, fg);
  }
}

class _StatusDot extends StatelessWidget {
  final StreamStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color color, bool glow) = switch (status) {
      StreamStatus.live => (AppColors.liveGreen, true),
      StreamStatus.dead => (const Color(0xFF444444), false),
      StreamStatus.checking => (AppColors.textTertiary, false),
      StreamStatus.unknown => (AppColors.textTertiary, false),
    };

    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: glow
            ? [BoxShadow(color: AppColors.liveGreenGlow, blurRadius: 6)]
            : null,
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.6, end: 1.0).animate(_controller),
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
