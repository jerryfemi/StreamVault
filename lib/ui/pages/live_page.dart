import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/channel.dart';
import '../../providers/providers.dart';

class LivePage extends ConsumerWidget {
  const LivePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(filteredChannelsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Live Now', style: AppTextStyles.statLabel),
        elevation: 0,
      ),
      body: channelsAsync.when(
        data: (channels) {
          final List<Channel> sports = [];
          final List<Channel> movies = [];

          for (final c in channels) {
            final nowPlaying = ref.watch(nowPlayingProvider(c.id));
            if (nowPlaying == null) continue;

            final cat = c.category.toLowerCase();
            final desc = nowPlaying.description.toLowerCase();

            bool isSport =
                cat == 'sports' ||
                desc.contains('league') ||
                desc.contains('cup') ||
                desc.contains('liga') ||
                desc.contains('serie') ||
                desc.contains('mls') ||
                desc.contains('sport') ||
                desc.contains('friendly');

            bool isMovie =
                cat == 'movies' ||
                desc.contains('movie') ||
                desc.contains('film') ||
                desc.contains('cinema');

            if (isSport) {
              sports.add(c);
            } else if (isMovie) {
              movies.add(c);
            }
          }

          final displaySports = sports.take(20).toList();
          final displayMovies = movies.take(10).toList();

          if (displaySports.isEmpty && displayMovies.isEmpty) {
            return const Center(
              child: Text(
                'No live sports or movies found.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              if (displaySports.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Text(
                      'Live Sports',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _LiveCard(channel: displaySports[index]),
                    );
                  }, childCount: displaySports.length),
                ),
              ],
              if (displayMovies.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                    child: Text(
                      'Live Movies',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _LiveCard(channel: displayMovies[index]),
                    );
                  }, childCount: displayMovies.length),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.accent),
          ),
        ),
      ),
    );
  }
}

class _LiveCard extends ConsumerWidget {
  final Channel channel;

  const _LiveCard({required this.channel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowPlaying = ref.watch(nowPlayingProvider(channel.id));
    if (nowPlaying == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        context.push('/browse/player/${Uri.encodeComponent(channel.id)}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail Area
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // A placeholder gradient background
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.surface, AppColors.bg],
                        ),
                      ),
                    ),

                    // Large Logo centered in the thumbnail
                    if (channel.logo.isNotEmpty)
                      Center(
                        child: Hero(
                          tag: 'logo_${channel.id}',
                          child: CachedNetworkImage(
                            imageUrl: channel.logo,
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                            errorWidget: (_, _, _) => const SizedBox(),
                          ),
                        ),
                      ),

                    // LIVE Badge
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.white, size: 8),
                            SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
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

            const SizedBox(height: 12),

            // Meta info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Small logo next to text
                ClipOval(
                  child: Container(
                    width: 40,
                    height: 40,
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(4),
                    child: CachedNetworkImage(
                      imageUrl: channel.logo,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.tv, color: AppColors.textTertiary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (nowPlaying.description.isNotEmpty) ...[
                        Text(
                          nowPlaying.description.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        nowPlaying.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        channel.name,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ends at ${TimeOfDay.fromDateTime(nowPlaying.end).format(context)}',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
