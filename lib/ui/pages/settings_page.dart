import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isCalculating = true;
  bool _isClearing = false;
  int _cacheSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  Future<void> _calculateCacheSize() async {
    setState(() => _isCalculating = true);
    int totalSize = 0;

    try {
      // 1. Hive cache size
      final appDocDir = await getApplicationDocumentsDirectory();
      final hiveBoxFile = File('${appDocDir.path}/channels_cache.hive');
      if (await hiveBoxFile.exists()) {
        totalSize += await hiveBoxFile.length();
      }

      // 2. DefaultCacheManager size (Image Cache)
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/libCachedImageData');
      if (await cacheDir.exists()) {
        totalSize += await _getDirSize(cacheDir);
      }
    } catch (e) {
      // Ignore errors if calculating cache size fails
      debugPrint('Error calculating cache size: $e');
    }

    if (mounted) {
      setState(() {
        _cacheSizeBytes = totalSize;
        _isCalculating = false;
      });
    }
  }

  Future<int> _getDirSize(Directory dir) async {
    int size = 0;
    try {
      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          size += await file.length();
        }
      }
    } catch (e) {
      // Ignore errors for individual files
    }
    return size;
  }

  Future<void> _clearCache() async {
    setState(() => _isClearing = true);

    try {
      // Clear Hive boxes (but keep structure)
      final box = Hive.box<dynamic>('channels_cache');
      await box.clear();

      // Clear Cached Images
      await DefaultCacheManager().emptyCache();

      // Recalculate
      await _calculateCacheSize();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully'),
            backgroundColor: AppColors.liveGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear cache'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Settings', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Storage', style: AppTextStyles.subtitle),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.storage,
                    color: AppColors.textPrimary,
                  ),
                  title: const Text(
                    'App Cache',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Stored channel listings and images',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  trailing: _isCalculating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        )
                      : Text(
                          _formatBytes(_cacheSizeBytes),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const Divider(color: AppColors.border, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_isCalculating ||
                              _isClearing ||
                              _cacheSizeBytes == 0)
                          ? null
                          : _clearCache,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        foregroundColor: AppColors.accent,
                        disabledBackgroundColor: AppColors.surfaceElevated
                            .withValues(alpha: 0.5),
                        disabledForegroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.button),
                        ),
                      ),
                      child: _isClearing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            )
                          : const Text(
                              'Clear Cache',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
