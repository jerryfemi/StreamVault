import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/router.dart';
import 'data/repositories/cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive CE
  await Hive.initFlutter();

  // Initialize the CacheManager (Registers adapters and opens boxes)
  final cacheManager = CacheManager();
  await cacheManager.init();

  runApp(const ProviderScope(child: StreamVaultApp()));
}

class StreamVaultApp extends ConsumerWidget {
  const StreamVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'StreamVault',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
