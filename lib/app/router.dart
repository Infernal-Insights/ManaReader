import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/library/shelves_screen.dart';
import '../features/reader/reader_screen.dart';
import '../features/sources_ui/sources_screen.dart';
import '../features/sources_ui/add_local_source_screen.dart';
import '../features/sources_ui/add_drive_source_screen.dart';
import '../features/settings/settings_screen.dart';
import '../core/db/database.dart';

/// Shell scaffold with bottom navigation.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), selectedIcon: Icon(Icons.collections_bookmark), label: 'Library'),
    NavigationDestination(icon: Icon(Icons.cloud_outlined), selectedIcon: Icon(Icons.cloud), label: 'Sources'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: _destinations,
      ),
    );
  }
}

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => _AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (_, __) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/library',
              builder: (_, __) => const LibraryScreen(),
              routes: [
                GoRoute(
                  path: 'shelves',
                  builder: (_, __) => const ShelvesScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/sources',
              builder: (_, __) => const SourcesScreen(),
              routes: [
                GoRoute(
                  path: 'add-local',
                  builder: (_, __) => const AddLocalSourceScreen(),
                ),
                GoRoute(
                  path: 'add-drive',
                  builder: (_, __) => const AddDriveSourceScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
      // Full-screen reader — outside shell
      GoRoute(
        path: '/reader/:seriesId',
        builder: (context, state) {
          final seriesId = state.pathParameters['seriesId']!;
          final startPage = int.tryParse(state.uri.queryParameters['page'] ?? '0') ?? 0;
          return ReaderScreen(seriesId: seriesId, initialPage: startPage);
        },
      ),
    ],
  );
}
