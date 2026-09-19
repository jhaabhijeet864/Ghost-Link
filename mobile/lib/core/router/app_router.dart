import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/workspaces/presentation/workspaces_dashboard_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_bottom_navigation.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationShell(),
      ),
    ],
  );
});

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const HomeScreen(),
      WorkspacesDashboardScreen(
        onNavigateTab: _onDestinationSelected, // Temporary until routing is fully implemented
      ),
      SettingsScreen(
        onNavigateTab: _onDestinationSelected, // Temporary until routing is fully implemented
      ),
    ];

    return AppScaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _selectedIndex,
        onTabSelected: _onDestinationSelected,
      ),
    );
  }
}
