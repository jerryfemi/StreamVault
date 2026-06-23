import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_vault/ui/shell/app_shell.dart';
import 'package:stream_vault/ui/pages/browse_page.dart';
import 'package:stream_vault/ui/pages/player_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/browse', // defaulting to Browse for now
    debugLogDiagnostics: kDebugMode,
    refreshListenable: ChangeNotifier(),
    redirect: (context, state) => null,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(shell: navigationShell),
        branches: [
          // 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const PlaceholderPage(title: 'Home'),
              ),
            ],
          ),
          // 1: Browse
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/browse',
                builder: (context, state) => const BrowsePage(),
                routes: [
                  GoRoute(
                    path: 'player/:channelId',
                    builder: (context, state) {
                      final channelId = Uri.decodeComponent(state.pathParameters['channelId']!);
                      return PlayerPage(channelId: channelId);
                    },
                  ),
                ],
              ),
            ],
          ),
          // 2: Saved
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saved',
                builder: (context, state) => const PlaceholderPage(title: 'Saved'),
              ),
            ],
          ),
          // 3: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const PlaceholderPage(title: 'Settings'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
