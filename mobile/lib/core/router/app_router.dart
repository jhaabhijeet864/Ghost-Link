import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/workspaces/presentation/workspaces_dashboard_screen.dart';
import '../../features/observe/presentation/observe_screen.dart';
import '../../features/session/control_room_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationShell(),
      ),
      GoRoute(
        path: '/pair',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          final ip = state.uri.queryParameters['ip'];
          final port = state.uri.queryParameters['port'];
          return MainNavigationShell(
            token: token,
            ip: ip,
            port: port,
            initialIndex: 1, // Jump to Observe screen on deep link pair
          );
        },
      ),
    ],
  );
});

class MainNavigationShell extends ConsumerStatefulWidget {
  final String? token;
  final String? ip;
  final String? port;
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    this.token,
    this.ip,
    this.port,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  late int _selectedIndex;
  late final String _ip;
  late final String _port;
  late final String _token;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _ip = widget.ip ?? '127.0.0.1';
    _port = widget.port ?? '8080';
    _token = widget.token ?? '';
  }

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ControlRoomScreen(
        onOpenWorkspaces: () => _onDestinationSelected(2),
        onOpenSettings: () => _onDestinationSelected(3),
      ),
      ObserveScreen(
        token: _token,
        ip: _ip,
        port: _port,
      ),
      WorkspacesDashboardScreen(
        onNavigateTab: _onDestinationSelected,
      ),
      SettingsScreen(
        onNavigateTab: _onDestinationSelected,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: const Color(0xFF0F1216),
        indicatorColor: const Color(0xFF1E2638),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub, color: Color(0xFF00E676)),
            label: 'Control Room',
          ),
          NavigationDestination(
            icon: Icon(Icons.visibility_outlined),
            selectedIcon: Icon(Icons.visibility, color: Colors.white),
            label: 'Observe',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_other_outlined),
            selectedIcon: Icon(Icons.devices_other, color: Colors.white),
            label: 'Workstations',
          ),
          NavigationDestination(
            icon: Icon(Icons.security_outlined),
            selectedIcon: Icon(Icons.security, color: Colors.white),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
