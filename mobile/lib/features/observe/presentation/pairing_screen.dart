import 'package:flutter/material.dart';

class PairingScreen extends StatelessWidget {
  final String? token;
  final String? ip;
  final String? port;

  const PairingScreen({super.key, this.token, this.ip, this.port});

  @override
  Widget build(BuildContext context) {
    if (token != null && token!.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Connecting')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Connecting to Desktop...'),
              Text('IP: $ip'),
              Text('Port: $port'),
              Text('Token: $token'),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('LocalLoop')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No Desktop Paired',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Scan the QR code on your Windows desktop bridge to connect LocalLoop.'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Implementation for manual pairing or scanning will go here
              },
              child: const Text('Pair with Desktop'),
            ),
          ],
        ),
      ),
    );
  }
}
