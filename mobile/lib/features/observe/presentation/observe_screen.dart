import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_loop/core/network/websocket_client.dart';
import 'package:local_loop/data/database/app_database.dart';

class ObserveScreen extends ConsumerStatefulWidget {
  final String? token;
  final String? ip;
  final String? port;

  const ObserveScreen({super.key, this.token, this.ip, this.port});

  @override
  ConsumerState<ObserveScreen> createState() => _ObserveScreenState();
}

class _ObserveScreenState extends ConsumerState<ObserveScreen> {
  final WebSocketClient _wsClient = WebSocketClient();
  final AppDatabase _db = AppDatabase();
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    if (widget.ip != null && widget.port != null && widget.token != null) {
      _wsClient.connect(widget.ip!, widget.port!, widget.token!);
    }
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await _db.getEvents();
    setState(() {
      _events = events;
    });
  }

  @override
  void dispose() {
    _wsClient.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Observe Mode')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red,
            width: double.infinity,
            child: const Text(
              'Connection Lost. Please ensure your desktop is on and connected to the same network. If network isolation prevents connection, try using a mobile hotspot as a fallback.',
              style: TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return ListTile(
                  title: Text(event['type'] ?? 'Unknown'),
                  subtitle: Text(event['payload']?.toString() ?? ''),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Disconnect logic
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Disconnect'),
                  content: const Text('Disconnect: Are you sure you want to forget this desktop? You will need to pair again using a QR code.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Yes')),
                  ],
                ),
              );
            },
            child: const Text('Disconnect & Forget Desktop'),
          )
        ],
      ),
    );
  }
}
