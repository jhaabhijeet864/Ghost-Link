import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_loop/core/network/websocket_client.dart';
import 'package:local_loop/data/database/app_database.dart';
import 'widgets/code_diff_viewer.dart';
import 'widgets/screenshot_previewer.dart';

enum TelemetryCategory { all, logs, diffs, terminal, errors }

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
  TelemetryCategory _selectedFilter = TelemetryCategory.all;
  String? _lastScreenshotBase64;
  bool _isRequestingScreenshot = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    if (widget.ip != null && widget.port != null && widget.token != null) {
      _connect();
    }
  }

  Future<void> _connect() async {
    try {
      await _wsClient.connect(widget.ip!, widget.port!, widget.token!);
      if (mounted) setState(() => _isConnected = true);

      _wsClient.messageStream.listen((data) {
        if (!mounted) return;

        final type = data['type'] as String?;
        if (type == 'screenshot_captured' || type == 'screenshot_result') {
          _handleScreenshotData(data);
        } else {
          _loadEvents();
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isConnected = false);
    }
  }

  void _handleScreenshotData(Map<String, dynamic> data) {
    try {
      String? base64Str;
      if (data['payload'] != null) {
        final payload = data['payload'];
        if (payload is String) {
          final decoded = jsonDecode(payload);
          base64Str = decoded['data'] as String?;
        } else if (payload is Map) {
          base64Str = payload['data'] as String?;
        }
      } else if (data['data'] != null && data['data']['base64'] != null) {
        base64Str = data['data']['base64'] as String?;
      }

      if (base64Str != null && base64Str.isNotEmpty) {
        setState(() {
          _lastScreenshotBase64 = base64Str;
          _isRequestingScreenshot = false;
        });
      }
    } catch (_) {
      setState(() => _isRequestingScreenshot = false);
    }
  }

  Future<void> _requestScreenshot() async {
    setState(() => _isRequestingScreenshot = true);
    final command = {
      'type': 'command_request',
      'data': {
        'intentId': DateTime.now().millisecondsSinceEpoch.toString(),
        'action': 'take_screenshot',
        'target': 'screen',
        'timestamp': DateTime.now().toIso8601String(),
      },
      'correlationId': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    await _wsClient.sendCommand(command);

    // Timeout safety fallback after 5 seconds if server drops packet
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isRequestingScreenshot) {
        setState(() => _isRequestingScreenshot = false);
      }
    });
  }

  Future<void> _loadEvents() async {
    final events = await _db.getEvents();
    if (mounted) {
      setState(() {
        _events = events;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredEvents {
    if (_selectedFilter == TelemetryCategory.all) return _events;

    return _events.where((e) {
      final type = (e['type'] as String? ?? '').toLowerCase();
      final payload = (e['payload']?.toString() ?? '').toLowerCase();

      switch (_selectedFilter) {
        case TelemetryCategory.logs:
          return type.contains('log') || type.contains('session') || type.contains('info');
        case TelemetryCategory.diffs:
          return type.contains('diff') || type.contains('file') || payload.contains('@@');
        case TelemetryCategory.terminal:
          return type.contains('terminal') || type.contains('stdout') || type.contains('stderr') || type.contains('cmd');
        case TelemetryCategory.errors:
          return type.contains('error') || payload.contains('exception') || payload.contains('error');
        default:
          return true;
      }
    }).toList();
  }

  int _getCategoryCount(TelemetryCategory category) {
    if (category == TelemetryCategory.all) return _events.length;

    return _events.where((e) {
      final type = (e['type'] as String? ?? '').toLowerCase();
      final payload = (e['payload']?.toString() ?? '').toLowerCase();

      switch (category) {
        case TelemetryCategory.logs:
          return type.contains('log') || type.contains('session') || type.contains('info');
        case TelemetryCategory.diffs:
          return type.contains('diff') || type.contains('file') || payload.contains('@@');
        case TelemetryCategory.terminal:
          return type.contains('terminal') || type.contains('stdout') || type.contains('stderr') || type.contains('cmd');
        case TelemetryCategory.errors:
          return type.contains('error') || payload.contains('exception') || payload.contains('error');
        default:
          return true;
      }
    }).length;
  }

  @override
  void dispose() {
    _wsClient.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Observe Mode'),
      ),
      body: Column(
        children: [
          if (!_isConnected && widget.ip != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF2A0D0D),
              width: double.infinity,
              child: Row(
                children: const [
                  Icon(Icons.wifi_off, color: Color(0xFFFF3D00), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Disconnected from desktop server. Check network connection.',
                      style: TextStyle(color: Color(0xFFFF8A80), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Horizontal Telemetry Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: TelemetryCategory.values.map((category) {
                  final isSelected = _selectedFilter == category;
                  final count = _getCategoryCount(category);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      showCheckmark: false,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getCategoryLabel(category),
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF090A0C) : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF090A0C).withValues(alpha: 0.2) : const Color(0xFF2A2E39),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF090A0C) : const Color(0xFF8A94A6),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      selectedColor: Colors.white,
                      backgroundColor: const Color(0xFF121418),
                      side: BorderSide(
                        color: isSelected ? Colors.white : const Color(0xFF2A2E39),
                      ),
                      onSelected: (_) => setState(() => _selectedFilter = category),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Event Stream & Widgets List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Host Screenshot Previewer Widget
                ScreenshotPreviewer(
                  lastScreenshotBase64: _lastScreenshotBase64,
                  onRequestScreenshot: _requestScreenshot,
                  isRequesting: _isRequestingScreenshot,
                ),

                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.filter_list_off, size: 40, color: Color(0xFF8A94A6)),
                          SizedBox(height: 12),
                          Text(
                            'No Events in Selected Category',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Try selecting "All" or trigger host actions.',
                            style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filtered.map((event) {
                    final type = (event['type'] as String? ?? '').toLowerCase();
                    final payload = event['payload']?.toString() ?? '';

                    // If code diff event, render CodeDiffViewer
                    if (type.contains('diff') || payload.contains('@@')) {
                      return CodeDiffViewer(
                        filePath: event['filePath']?.toString() ?? 'Code Modification',
                        diffContent: payload,
                      );
                    }

                    // Standard Telemetry Log Card
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
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
                              Icon(
                                _getEventIcon(type),
                                color: _getEventColor(type),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                event['type'] ?? 'Telemetry Event',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Spacer(),
                              Text(
                                event['timestamp']?.toString() ?? '',
                                style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 11),
                              ),
                            ],
                          ),
                          if (payload.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              payload,
                              style: const TextStyle(
                                color: Color(0xFFC3C7D0),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryLabel(TelemetryCategory category) {
    switch (category) {
      case TelemetryCategory.all: return 'All';
      case TelemetryCategory.logs: return 'Agent Logs';
      case TelemetryCategory.diffs: return 'Diffs';
      case TelemetryCategory.terminal: return 'Terminal';
      case TelemetryCategory.errors: return 'Errors';
    }
  }

  IconData _getEventIcon(String type) {
    if (type.contains('error')) return Icons.error_outline;
    if (type.contains('terminal') || type.contains('stdout')) return Icons.terminal;
    if (type.contains('session')) return Icons.power_settings_new;
    return Icons.article_outlined;
  }

  Color _getEventColor(String type) {
    if (type.contains('error')) return const Color(0xFFFF3D00);
    if (type.contains('terminal') || type.contains('stdout')) return const Color(0xFF00E676);
    if (type.contains('session')) return const Color(0xFFFFB300);
    return const Color(0xFF8A94A6);
  }
}
