import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/connection_state.dart';
import '../state/command_queue_manager.dart';
import '../theme/app_colors.dart';

class ConnectionStatusPill extends ConsumerWidget {
  const ConnectionStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionStateProvider);

    Color dotColor;
    String statusText;
    bool showSpinner = false;
    VoidCallback? onTap;

    switch (connection.status) {
      case LinkStatus.connected:
        dotColor = AppColors.accent; // #00E676 Neon Green
        final latency = connection.latencyMs;
        statusText = latency != null ? 'LIVE • ${latency}ms' : 'LIVE';
        break;
      case LinkStatus.authenticating:
        dotColor = AppColors.accentCyan;
        statusText = 'AUTHENTICATING';
        showSpinner = true;
        break;
      case LinkStatus.reconnecting:
        dotColor = AppColors.warning;
        statusText = 'RECONNECTING';
        showSpinner = true;
        break;
      case LinkStatus.disconnected:
        dotColor = AppColors.error;
        statusText = 'OFFLINE';
        onTap = () {
          ref.read(connectionStateProvider.notifier).connect(
                ip: connection.hostIp ?? '127.0.0.1',
                port: connection.hostPort ?? '8080',
              );
        };
        break;
    }

    return ValueListenableBuilder<int>(
      valueListenable: CommandQueueManager().queueCountNotifier,
      builder: (context, queueCount, _) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0E14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dotColor.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.12),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showSpinner)
                  SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: dotColor,
                    ),
                  )
                else
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: dotColor.withValues(alpha: 0.8),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: dotColor,
                    fontFamily: 'monospace',
                  ),
                ),
                if (queueCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$queueCount queued',
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (connection.isOffline) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.refresh, size: 11, color: AppColors.error),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
