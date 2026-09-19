import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/workspaces/presentation/workspaces_dashboard_screen.dart';
import '../../features/observe/presentation/observe_screen.dart';
import '../../features/command/command_composer_screen.dart';
import '../../features/command/approval_inbox_screen.dart';
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
  late final String _deviceId;
  late final String _ip;
  late final String _port;
  late final String _token;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _deviceId = widget.token ?? 'unknown';
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
      WorkspacesDashboardScreen(
        onNavigateTab: _onDestinationSelected,
      ),
      ObserveScreen(
        token: _token,
        ip: _ip,
        port: _port,
      ),
      CommandComposerScreen(
        deviceId: _deviceId,
        ip: _ip,
        port: _port,
        token: _token,
      ),
      ApprovalInboxScreen(
        deviceId: _deviceId,
        ip: _ip,
        port: _port,
        token: _token,
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
            icon: Icon(Icons.devices_other_outlined),
            selectedIcon: Icon(Icons.devices_other, color: Colors.white),
            label: 'Workspaces',
          ),
          NavigationDestination(
            icon: Icon(Icons.visibility_outlined),
            selectedIcon: Icon(Icons.visibility, color: Colors.white),
            label: 'Observe',
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal_outlined),
            selectedIcon: Icon(Icons.terminal, color: Colors.white),
            label: 'Command',
          ),
          NavigationDestination(
            icon: Icon(Icons.approval_outlined),
            selectedIcon: Icon(Icons.approval, color: Colors.white),
            label: 'Approvals',
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
