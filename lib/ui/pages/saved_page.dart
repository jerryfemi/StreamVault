import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_vault/ui/widgets/saved/saved_channel_tile.dart';
import 'package:stream_vault/ui/widgets/saved/saved_summary_cards.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';

class SavedPage extends ConsumerWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedChannelsAsync = ref.watch(savedChannelsProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Page Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saved', style: AppTextStyles.heading1),
                      const SizedBox(height: 2),
                      const Text(
                        'Your favourite channels',
                        style: AppTextStyles.subtitle,
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
          ),

          // ── Summary Cards ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: savedChannelsAsync.when(
                data: (data) {
                  final liveCount = data['live']?.length ?? 0;
                  final totalCount =
                      (data['live']?.length ?? 0) +
                      (data['offline']?.length ?? 0);
                  return SavedSummaryCards(
                    savedCount: totalCount,
                    liveCount: liveCount,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (e, _) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Lists ──
          savedChannelsAsync.when(
            data: (data) {
              final liveChannels = data['live'] ?? [];
              final offlineChannels = data['offline'] ?? [];

              return SliverList(
                delegate: SliverChildListDelegate([
                  if (liveChannels.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.liveGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Now Playing',
                                style: AppTextStyles.heading2,
                              ),
                            ],
                          ),
                          Text(
                            '${liveChannels.length} of ${liveChannels.length + offlineChannels.length}',
                            style: AppTextStyles.subtitle.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...liveChannels.map(
                      (c) => SavedChannelTile(
                        channel: c,
                        isLive: true,
                        onTap: () => context.push(
                          '/browse/player/${Uri.encodeComponent(c.id)}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  if (offlineChannels.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Other Channels', style: AppTextStyles.heading2),
                          Text(
                            '${offlineChannels.length}',
                            style: AppTextStyles.subtitle.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...offlineChannels.map(
                      (c) => SavedChannelTile(
                        channel: c,
                        isLive: false,
                        onTap: () => context.push(
                          '/browse/player/${Uri.encodeComponent(c.id)}',
                        ),
                      ),
                    ),
                  ],
                ]),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(
                child: Text('Error: $e', style: AppTextStyles.subtitle),
              ),
            ),
          ),

          // Bottom padding for nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
