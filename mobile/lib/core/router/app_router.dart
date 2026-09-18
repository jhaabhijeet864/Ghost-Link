import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/observe/presentation/observe_screen.dart';

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
          return ObserveScreen(token: token, ip: ip, port: port);
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
