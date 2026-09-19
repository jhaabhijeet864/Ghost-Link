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
      appBar: AppBar(
        title: const Text('Observe Mode'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF2A0D0D),
            width: double.infinity,
            child: Row(
              children: const [
                Icon(Icons.wifi_off, color: Color(0xFFFF3D00), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Connection Lost. Check local network or desktop service state.',
                    style: TextStyle(color: Color(0xFFFF8A80), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _events.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.terminal, size: 48, color: Color(0xFF8A94A6)),
                        SizedBox(height: 12),
                        Text('No Events Streamed Yet', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Event logs from desktop will stream here in real time.', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121418),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2A2E39)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.code, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  event['type'] ?? 'Unknown Event',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Spacer(),
                                Text(
                                  event['timestamp']?.toString() ?? '',
                                  style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 11),
                                ),
                              ],
                            ),
                            if (event['payload'] != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                event['payload']?.toString() ?? '',
                                style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12, fontFamily: 'monospace'),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.link_off, size: 18, color: Color(0xFFFF3D00)),
                label: const Text('Disconnect & Forget Desktop', style: TextStyle(color: Color(0xFFFF3D00), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF3D00)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF121418),
                      title: const Text('Disconnect Desktop', style: TextStyle(color: Colors.white)),
                      content: const Text(
                        'Are you sure you want to forget this desktop? You will need to re-pair via QR code.',
                        style: TextStyle(color: Color(0xFF8A94A6)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF3D00)),
                          child: const Text('Disconnect'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
