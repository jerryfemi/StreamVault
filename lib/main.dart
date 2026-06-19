import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'data/repositories/cache_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive CE
  await Hive.initFlutter();

  // Initialize the CacheManager (Registers adapters and opens boxes)
  final cacheManager = CacheManager();
  await cacheManager.init();

  runApp(StreamVaultApp());
}

class StreamVaultApp extends StatelessWidget {
  const StreamVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreamVault',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StreamVault')),
      body: const Center(child: Text('Dashboard Placeholder')),
    );
  }
}
