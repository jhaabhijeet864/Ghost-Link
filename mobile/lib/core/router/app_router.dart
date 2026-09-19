import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/observe/presentation/observe_screen.dart';
import '../../features/command/command_composer_screen.dart';
import '../../features/command/approval_inbox_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DefaultScreen(),
      ),
      GoRoute(
        path: '/pair',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          final ip = state.uri.queryParameters['ip'];
          final port = state.uri.queryParameters['port'];
          return MainNavigationShell(token: token, ip: ip, port: port);
        },
      ),
    ],
  );
});

class DefaultScreen extends StatelessWidget {
  const DefaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LocalLoop')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No Desktop Paired',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan the QR code on your Windows desktop bridge to connect LocalLoop.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // Wait for deep link.
                },
                child: const Text('Pair with Desktop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigationShell extends ConsumerStatefulWidget {
  final String? token;
  final String? ip;
  final String? port;

  const MainNavigationShell({
    super.key,
    this.token,
    this.ip,
    this.port,
  });

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _selectedIndex = 0;
  late final String _deviceId;
  late final String _ip;
  late final String _port;
  late final String _token;

  @override
  void initState() {
    super.initState();
    _deviceId = widget.token ?? 'unknown';
    _ip = widget.ip ?? 'localhost';
    _port = widget.port ?? '8080';
    _token = widget.token ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      ObserveScreen(token: _token, ip: _ip, port: _port),
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
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.visibility),
            selectedIcon: Icon(Icons.visibility),
            label: 'Observe',
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal),
            selectedIcon: Icon(Icons.terminal),
            label: 'Command',
          ),
          NavigationDestination(
            icon: Icon(Icons.approval),
            selectedIcon: Icon(Icons.approval),
            label: 'Approvals',
          ),
        ],
      ),
    );
  }
}
