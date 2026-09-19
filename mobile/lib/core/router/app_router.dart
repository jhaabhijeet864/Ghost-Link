import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/workspaces/presentation/workspaces_dashboard_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/machines/presentation/machines_list_screen.dart';
import '../../features/machines/presentation/machine_detail_screen.dart';
import '../../features/pairing/presentation/pairing_flow_screen.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_bottom_navigation.dart';
import '../../features/workspaces/presentation/workspace_detail_screen.dart';
import '../../features/session/presentation/sessions_list_screen.dart';
import '../../features/session/presentation/new_session_screen.dart';
import '../../features/session/presentation/session_detail_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationShell(),
      ),
      GoRoute(
        path: '/machines',
        builder: (context, state) => MachinesListScreen(
          onNavigateTab: (idx) {}, // dummy callback
        ),
      ),
      GoRoute(
        path: '/machine/:id',
        builder: (context, state) => MachineDetailScreen(
          machineId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/pairing',
        builder: (context, state) => const PairingFlowScreen(),
      ),
      GoRoute(
        path: '/workspace/:id',
        builder: (context, state) => WorkspaceDetailScreen(
          workspaceId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/sessions',
        builder: (context, state) => const SessionsListScreen(),
      ),
      GoRoute(
        path: '/new-session',
        builder: (context, state) => const NewSessionScreen(),
      ),
      GoRoute(
        path: '/session/:id',
        builder: (context, state) => SessionDetailScreen(
          sessionId: state.pathParameters['id']!,
          title: 'Agent Session', // Added title parameter
        ),
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
      const SessionsListScreen(),
      MachinesListScreen(
        onNavigateTab: _onDestinationSelected, // Temporary until routing is fully implemented
      ),
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
