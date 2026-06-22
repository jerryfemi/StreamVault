import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final channel = channels[index];
                    return ChannelCard(
                      channel: channel,
                      onTap: () {
                        // TODO: Navigate to player
                      },
                      onLongPress: () {
                        ref
                            .read(favoritesProvider.notifier)
                            .toggleFavorite(channel.id);
                      },
                    );
                  },
                  childCount: channels.length,
                ),
              ),
            ),
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Failed to load channels\n$e',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subtitle,
                ),
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
        ],
      ),
    );
  }
}

/// Category tab bar — All | Sports | Movies | Favorites
class _CategoryTabs extends ConsumerWidget {
  final String activeCategory;
  final AsyncValue allChannels;

  const _CategoryTabs({
    required this.activeCategory,
    required this.allChannels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ['Sports', 'Movies', 'Favorites'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.tabContainer),
      ),
      child: Row(
        children: categories.map((cat) {
          final isActive = activeCategory == cat;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(activeCategoryProvider.notifier).state = cat,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.textPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.tab),
                ),
                alignment: Alignment.center,
                child: Text(
                  cat,
                  style: AppTextStyles.tabText.copyWith(
                    color: isActive ? AppColors.bg : AppColors.textSecondary,
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
