import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_vault/ui/shell/app_shell.dart';
import 'package:stream_vault/ui/pages/admin_page.dart';
import 'package:stream_vault/ui/pages/browse_page.dart';
import 'package:stream_vault/ui/pages/player_page.dart';
import 'package:stream_vault/ui/pages/saved_page.dart';
import 'package:stream_vault/ui/pages/settings_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/browse', // defaulting to Browse for now
    debugLogDiagnostics: kDebugMode,
    refreshListenable: ChangeNotifier(),
    redirect: (context, state) => null,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(shell: navigationShell),
        branches: [
          // 0: Browse
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/browse',
                builder: (context, state) => const BrowsePage(),
                routes: [
                  GoRoute(
                    path: 'player/:channelId',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final channelId = Uri.decodeComponent(state.pathParameters['channelId']!);
                      return PlayerPage(channelId: channelId);
                    },
                  ),
                ],
              ),
            ],
          ),
          // 1: Saved
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saved',
                builder: (context, state) => const SavedPage(),
              ),
            ],
          ),
          // 2: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      // Admin portal — overlays above the shell, not in the bottom nav
      GoRoute(
        path: '/admin',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AdminPage(),
      ),
    ],
  );
});
