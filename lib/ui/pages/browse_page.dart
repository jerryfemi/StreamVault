import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../widgets/channel_card.dart';

/// Browse page — 2-column grid of all channels with category tabs & search.
///
/// Matches the Browse design (browse.html) exactly.
class BrowsePage extends ConsumerWidget {
  const BrowsePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(filteredChannelsProvider);
    final activeCategory = ref.watch(activeCategoryProvider);
    final allChannels = ref.watch(allChannelsProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Page Header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Browse', style: AppTextStyles.heading1),
                  const SizedBox(height: 2),
                  Text('All verified channels', style: AppTextStyles.subtitle),
                ],
              ),
            ),
          ),

          // ── Search Bar ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: _SearchBar(),
            ),
          ),

          // ── Category Tabs ──
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategoryTabsDelegate(
              child: _CategoryTabs(
                activeCategory: activeCategory,
                allChannels: allChannels,
              ),
            ),
          ),

          // ── Sort Row ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: channelsAsync.when(
                data: (channels) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.subtitle,
                        children: [
                          const TextSpan(text: 'Showing '),
                          TextSpan(
                            text: '${channels.length}',
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: ' channels'),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadii.button),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.sort,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Live first',
                            style: AppTextStyles.channelName.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ),

          // ── Channel Grid ──
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          channelsAsync.when(
            data: (channels) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final channel = channels[index];
                  return ChannelCard(
                    channel: channel,
                    onTap: () {
                      context.push(
                        '/browse/player/${Uri.encodeComponent(channel.id)}',
                      );
                    },
                    onLongPress: () {
                      ref
                          .read(favoritesProvider.notifier)
                          .toggleFavorite(channel.id);
                    },
                  );
                }, childCount: channels.length),
              ),
            ),
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
            error: (e, _) {
              print(e);
              return SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Failed to load channels\n$e',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle,
                  ),
                ),
              );
            },
          ),

          // Bottom padding for nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

/// Search bar matching the design exactly.
class _SearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.searchBar),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textTertiary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (query) =>
                  ref.read(searchQueryProvider.notifier).state = query,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search by name or programme…',
                hintStyle: AppTextStyles.searchHint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Icon(
            Icons.filter_list,
            color: AppColors.textTertiary,
            size: 18,
          ),
        ],
      ),
    );
  }
}

/// Category tab bar — All | Sports | Movies
class _CategoryTabs extends ConsumerWidget {
  final String activeCategory;
  final AsyncValue allChannels;

  const _CategoryTabs({
    required this.activeCategory,
    required this.allChannels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = allChannels.valueOrNull ?? [];
    final allCount = channels.length;
    final sportsCount = channels.where((c) => c.category == 'Sports').length;
    final moviesCount = channels.where((c) => c.category == 'Movies').length;

    final categories = [
      {'name': 'All', 'count': allCount},
      {'name': 'Sports', 'count': sportsCount},
      {'name': 'Movies', 'count': moviesCount},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.tabContainer),
      ),
      child: Row(
        children: categories.map((catData) {
          final catName = catData['name'] as String;
          final catCount = catData['count'] as int;
          final isActive = activeCategory == catName;

          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(activeCategoryProvider.notifier).state = catName,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.textPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.tab),
                ),
                alignment: Alignment.center,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: catName,
                        style: AppTextStyles.tabText.copyWith(
                          color: isActive
                              ? AppColors.bg
                              : AppColors.textSecondary,
                        ),
                      ),
                      if (catCount > 0)
                        TextSpan(
                          text: '  $catCount',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? AppColors.bg.withValues(alpha: 0.5)
                                : AppColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _CategoryTabsDelegate({required this.child});

  @override
  double get minExtent => 68.0;

  @override
  double get maxExtent => 68.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryTabsDelegate oldDelegate) {
    return true;
  }
}
