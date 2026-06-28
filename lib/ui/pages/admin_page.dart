import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/remote_config.dart';
import '../../providers/providers.dart';

class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  late final TextEditingController _tokenController;
  bool _tokenObscured = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    final admin = ref.read(adminSettingsProvider.notifier);
    _tokenController = TextEditingController(text: admin.token);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _syncToGithub() async {
    final admin = ref.read(adminSettingsProvider.notifier);
    final token = _tokenController.text.trim();

    if (token.isEmpty) {
      _showSnackBar('Enter a GitHub token first', isError: true);
      return;
    }

    // Save token locally
    admin.setToken(token);

    setState(() => _syncing = true);

    // Gather favorites as top channels
    final favorites = ref.read(favoritesProvider);
    // Gather locally-detected dead channels
    final localDead = ref.read(localDeadChannelsProvider);

    // Gather custom EPG data
    final customEpg = ref.read(adminCustomEpgProvider);

    final config = RemoteConfig(
      topChannels: favorites,
      deadChannels: localDead,
      customEpg: customEpg,
    );

    final service = ref.read(githubConfigServiceProvider);
    final success = await service.pushConfig(
      token: token,
      owner: admin.owner,
      repo: admin.repo,
      path: 'config.json',
      config: config,
    );

    if (mounted) {
      setState(() => _syncing = false);
      if (success) {
        // Refresh remote config so the local state updates immediately
        ref.invalidate(remoteConfigProvider);
        _showSnackBar('Config synced to GitHub ✓');
      } else {
        _showSnackBar('Sync failed — check token & repo', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.accent : AppColors.liveGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    final localDead = ref.watch(localDeadChannelsProvider);
    final channelsAsync = ref.watch(allChannelsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_outlined,
              color: AppColors.liveGreen,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Admin Portal',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.liveGreen,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SlideTransition(
          position: _slideUp,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ═══════════════════════════════════════════════
              // GITHUB TOKEN
              // ═══════════════════════════════════════════════
              _SectionHeader(
                icon: Icons.key_rounded,
                title: 'GitHub Token',
                subtitle: 'Personal Access Token with repo scope',
              ),
              const SizedBox(height: 12),
              _buildTokenField(),
              const SizedBox(height: 28),

              // ═══════════════════════════════════════════════
              // TOP CHANNELS (Favorites)
              // ═══════════════════════════════════════════════
              _SectionHeader(
                icon: Icons.star_rounded,
                title: 'Top Channels',
                subtitle:
                    '${favorites.length} favorites → pushed as top_channels',
                iconColor: AppColors.liveGreen,
              ),
              const SizedBox(height: 12),
              _buildIdListCard(
                ids: favorites,
                emptyText:
                    'No favorites yet — heart channels to add them here.',
                channelsAsync: channelsAsync,
                accentColor: AppColors.liveGreen,
              ),
              const SizedBox(height: 28),

              // ═══════════════════════════════════════════════
              // DEAD CHANNELS
              // ═══════════════════════════════════════════════
              _SectionHeader(
                icon: Icons.block_rounded,
                title: 'Dead Channels',
                subtitle:
                    '${localDead.length} detected — pushed as dead_channels',
                iconColor: AppColors.accent,
              ),
              const SizedBox(height: 12),
              _buildIdListCard(
                ids: localDead,
                emptyText:
                    'No dead channels detected yet — scroll the browse page.',
                channelsAsync: channelsAsync,
                accentColor: AppColors.accent,
                onClearAll: () {
                  ref.read(localDeadChannelsProvider.notifier).clearAll();
                },
              ),
              const SizedBox(height: 36),

              // ═══════════════════════════════════════════════
              // SYNC BUTTON
              // ═══════════════════════════════════════════════
              _buildSyncButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Token Field ──────────────────────────────────────────────────

  Widget _buildTokenField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _tokenController,
              obscureText: _tokenObscured,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontFamily: 'monospace',
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'ghp_xxxxxxxxxxxx',
                hintStyle: TextStyle(color: AppColors.textTertiary),
              ),
              onChanged: (val) {
                ref.read(adminSettingsProvider.notifier).setToken(val.trim());
              },
            ),
          ),
          IconButton(
            icon: Icon(
              _tokenObscured
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () => setState(() => _tokenObscured = !_tokenObscured),
          ),
        ],
      ),
    );
  }

  // ── ID List Card ─────────────────────────────────────────────────

  Widget _buildIdListCard({
    required Set<String> ids,
    required String emptyText,
    required AsyncValue channelsAsync,
    required Color accentColor,
    VoidCallback? onClearAll,
  }) {
    if (ids.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          emptyText,
          textAlign: TextAlign.center,
          style: AppTextStyles.subtitle.copyWith(
            color: AppColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final sortedIds = ids.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header row with copy & clear buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  '${sortedIds.length} IDs',
                  style: AppTextStyles.caption.copyWith(
                    color: accentColor,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                // Copy button
                _SmallActionButton(
                  icon: Icons.copy_rounded,
                  label: 'Copy',
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: sortedIds.join('\n')),
                    );
                    _showSnackBar('Copied ${sortedIds.length} IDs');
                  },
                ),
                if (onClearAll != null) ...[
                  const SizedBox(width: 8),
                  _SmallActionButton(
                    icon: Icons.delete_sweep_outlined,
                    label: 'Clear',
                    onTap: onClearAll,
                    color: AppColors.accent,
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          // Scrollable list (max 200px tall)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: sortedIds.length,
              itemBuilder: (context, index) {
                final id = sortedIds[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 3,
                  ),
                  child: Text(
                    id,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Sync Button ──────────────────────────────────────────────────

  Widget _buildSyncButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _syncing ? null : _syncToGithub,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          elevation: 0,
        ),
        child: _syncing
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Sync to GitHub',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.heading2.copyWith(fontSize: 15)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
