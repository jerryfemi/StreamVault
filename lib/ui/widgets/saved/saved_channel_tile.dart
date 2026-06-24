import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:stream_vault/data/models/stream_status.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/country_helper.dart';
import '../../../data/models/channel.dart';
import '../../../providers/providers.dart';

class SavedChannelTile extends ConsumerWidget {
  final Channel channel;
  final bool isLive;
  final VoidCallback onTap;

  const SavedChannelTile({
    super.key,
    required this.channel,
    required this.isLive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider(channel.tvgId));
    final status = ref.watch(streamStatusProvider)[channel.id];
    final isDead = status == StreamStatus.dead;
    final isActuallyOffline = isDead || !isLive;

    return VisibilityDetector(
      key: Key('saved_channel_tile_${channel.id}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1) {
          ref.read(streamStatusProvider.notifier).validateIfUnknown(
                channel.id,
                channel.streamUrl,
                channel.headers,
              );
        }
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: isActuallyOffline
                      ? const Color(0xFF444444)
                      : AppColors.liveGreen,
                  width: 3,
                ),
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ── Logo ──
                Opacity(
                  opacity: isActuallyOffline ? 0.4 : 1.0,
                  child: _buildLogo(),
                ),
                const SizedBox(width: 12),

                // ── Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name,
                        style: AppTextStyles.channelName.copyWith(
                          fontSize: 15,
                          color: isActuallyOffline
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (isActuallyOffline)
                        const Text(
                          'No active programme',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else if (nowPlaying != null)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                nowPlaying.title,
                                style: AppTextStyles.epgTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      else
                        const Text(
                          'No programme info',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            CountryHelper.getFlag(channel.id),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            CountryHelper.getName(channel.id),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          if (isActuallyOffline) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF333333),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Ready',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Play Button ──
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActuallyOffline
                        ? const Color(0xFF2A2A2A)
                        : const Color(0x26E5383B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: isActuallyOffline
                        ? AppColors.textTertiary
                        : AppColors.accent,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildLogo() {
    final colors = _logoColors(channel.name);
    final abbrev = _abbreviation(channel.name);

    if (channel.logo.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          channel.logo,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallbackLogo(abbrev, colors),
        ),
      );
    }
    return _fallbackLogo(abbrev, colors);
  }

  Widget _fallbackLogo(String abbrev, (Color, Color) colors) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        abbrev,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 20,
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
