import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

final activeTabProvider = StateProvider<int>((ref) => 0);

class AppShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const AppShell({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _BottomNav(
        currentIndex: shell.currentIndex,
        shell: shell,
      ),
    );
  }
}

// Custom bottom nav bar matching the design exactly.
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final StatefulNavigationShell shell;
  const _BottomNav({required this.currentIndex, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xEB141418), // surface 92%
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.explore_rounded,
            label: 'Browse',
            isActive: currentIndex == 0,
            onTap: () => shell.goBranch(0, initialLocation: currentIndex == 0),
          ),
          _NavItem(
            icon: Icons.favorite_rounded,
            label: 'Saved',
            isActive: currentIndex == 1,
            onTap: () => shell.goBranch(1, initialLocation: currentIndex == 1),
          ),
          _NavItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            isActive: currentIndex == 2,
            onTap: () => shell.goBranch(2, initialLocation: currentIndex == 2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active indicator line
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 2,
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: isActive ? AppColors.textPrimary : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Icon(
            icon,
            size: 22,
            color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.navLabel.copyWith(
              color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Temporary placeholder for pages not yet built.
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(title, style: AppTextStyles.heading1)),
    );
  }
}
