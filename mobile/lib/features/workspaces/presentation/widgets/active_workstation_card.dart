import 'package:flutter/material.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/security/device_manager.dart';

class ActiveWorkstationCard extends StatefulWidget {
  final SavedDevice? activeDevice;
  final VoidCallback onDisconnect;
  final VoidCallback onReconnect;
  final VoidCallback onSwitch;

  const ActiveWorkstationCard({
    super.key,
    required this.activeDevice,
    required this.onDisconnect,
    required this.onReconnect,
    required this.onSwitch,
  });

  @override
  State<ActiveWorkstationCard> createState() => _ActiveWorkstationCardState();
}

class _ActiveWorkstationCardState extends State<ActiveWorkstationCard> with SingleTickerProviderStateMixin {
  final WebSocketClient _client = WebSocketClient();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return const Color(0xFF00E676); // Vibrant Green
      case ConnectionStatus.connecting:
      case ConnectionStatus.authenticating:
        return const Color(0xFFFFB300); // Amber
      case ConnectionStatus.disconnected:
        return const Color(0xFFFF5252); // Red
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Online • Encrypted';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.authenticating:
        return 'Authenticating...';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.activeDevice;
    if (device == null) {
      return const SizedBox.shrink();
    }

    final machineName = _client.activeMachineName ?? device.machineName ?? device.name;

    return StreamBuilder<ConnectionStatus>(
      stream: _client.statusStream,
      initialData: _client.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectionStatus.disconnected;
        final statusColor = _getStatusColor(status);
        final isConnected = status == ConnectionStatus.connected;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF13161C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isConnected ? const Color(0xFF1E293B) : const Color(0xFF2A1C1C),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isConnected
                    ? const Color(0xFF00E676).withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E222B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.laptop_windows, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          machineName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${device.ip}:${device.port}',
                          style: const TextStyle(
                            color: Color(0xFF8A94A6),
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Live Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: isConnected
                              ? _pulseController.drive(Tween<double>(begin: 0.4, end: 1.0))
                              : const AlwaysStoppedAnimation(1.0),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusText(status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF222733), height: 1),
              const SizedBox(height: 14),
              // Latency & Security Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Color(0xFF8A94A6), size: 16),
                      const SizedBox(width: 6),
                      ValueListenableBuilder<int?>(
                        valueListenable: _client.latencyNotifier,
                        builder: (context, latency, child) {
                          return Text(
                            latency != null ? '$latency ms latency' : (isConnected ? 'Measuring...' : 'N/A'),
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.security, color: Color(0xFF00E676), size: 15),
                      const SizedBox(width: 5),
                      const Text(
                        'Ed25519 Signed',
                        style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        isConnected ? Icons.link_off : Icons.refresh,
                        size: 16,
                      ),
                      label: Text(isConnected ? 'Disconnect' : 'Reconnect'),
                      onPressed: isConnected ? widget.onDisconnect : widget.onReconnect,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isConnected ? const Color(0xFFFF8A80) : Colors.white,
                        side: BorderSide(
                          color: isConnected
                              ? const Color(0xFFFF5252).withValues(alpha: 0.3)
                              : const Color(0xFF2A2E39),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.swap_horiz, size: 16),
                      label: const Text('Switch Host'),
                      onPressed: widget.onSwitch,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF2A2E39)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
