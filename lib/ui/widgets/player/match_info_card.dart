import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/channel.dart';
import '../../../data/models/epg_programme.dart';
import '../../../providers/providers.dart';
import 'action_button.dart';
import 'meta_chip.dart';

class MatchInfoCard extends StatelessWidget {
  final Channel channel;
  final EpgProgramme? nowPlaying;

  const MatchInfoCard({
    super.key,
    required this.channel,
    required this.nowPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                  channel.name.substring(0, 2).toUpperCase(),
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
                  channel.name,
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
                  final isFav = favs.contains(channel.id);
                  return Row(
                    children: [
                      ActionButton(
                        icon: isFav ? Icons.favorite : Icons.favorite_border,
                        iconColor: isFav
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        onTap: () {
                          ref
                              .read(favoritesProvider.notifier)
                              .toggleFavorite(channel.id);
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionButton(
                        icon: Icons.flag_outlined,
                        iconColor: AppColors.textSecondary,
                        onTap: () {
                          ref
                              .read(localDeadChannelsProvider.notifier)
                              .markDead(channel.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Channel reported as dead.'),
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
                    nowPlaying!.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.3,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (nowPlaying!.description.isNotEmpty)
                    Text(
                      nowPlaying!.description,
                      style: const TextStyle(
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
                      MetaChip(
                        icon: Icons.access_time,
                        text:
                            'Ends ${nowPlaying!.end.toLocal().hour.toString().padLeft(2, '0')}:${nowPlaying!.end.toLocal().minute.toString().padLeft(2, '0')}',
                      ),
                      MetaChip(
                        icon: Icons.hourglass_bottom,
                        text: '${nowPlaying!.timeRemaining.inMinutes} min left',
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
              child: const Text(
                'No programme information available',
                style: AppTextStyles.subtitle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
