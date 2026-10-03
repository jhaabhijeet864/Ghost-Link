import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/connection_status_pill.dart';
import '../../../core/state/connection_state.dart';
import '../../../core/state/telemetry_state.dart';
import '../../../core/network/websocket_client.dart';
import 'widgets/code_diff_viewer.dart';
import 'widgets/screenshot_previewer.dart';

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
  String? _lastScreenshotBase64;
  bool _isRequestingScreenshot = false;

  @override
  void initState() {
    super.initState();
    if (widget.ip != null && widget.port != null && widget.token != null) {
      ref.read(connectionStateProvider.notifier).connect(
            ip: widget.ip!,
            port: widget.port!,
            pairingSecret: widget.token,
          );
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

    try {
      await _wsClient.sendCommand(command);
    } catch (_) {}

    // Timeout safety fallback after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isRequestingScreenshot) {
        setState(() => _isRequestingScreenshot = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = ref.watch(telemetryProvider);
    final filteredLogs = telemetry.filteredLogs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Observe Mode',
          style: AppTypography.screenTitle.copyWith(fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Center(child: ConnectionStatusPill()),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Horizontal Telemetry Filter Chips
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: TelemetryFilter.values.map((filter) {
                    final isSelected = telemetry.activeFilter == filter;
                    final count = _getFilterCount(telemetry.allLogs, filter);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: isSelected,
                        showCheckmark: false,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getFilterLabel(filter),
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF090A0C) : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF090A0C).withValues(alpha: 0.2)
                                    : AppColors.surfacePressed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF090A0C) : AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.surfaceElevated,
                        side: BorderSide(
                          color: isSelected ? AppColors.accent : AppColors.borderMetal,
                        ),
                        onSelected: (_) => ref.read(telemetryProvider.notifier).setFilter(filter),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Activity Stream & Widgets List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  // Host Screenshot Previewer Widget
                  ScreenshotPreviewer(
                    lastScreenshotBase64: _lastScreenshotBase64,
                    onRequestScreenshot: _requestScreenshot,
                    isRequesting: _isRequestingScreenshot,
                  ),

                  const SizedBox(height: 10),

                  if (filteredLogs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.filter_list_off, size: 36, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text(
                              'No Activity in Selected Category',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Listening for live events from host workstation...',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredLogs.map((log) {
                      // If code diff event, render CodeDiffViewer
                      if (log.category == TelemetryFilter.diffs || log.message.contains('@@')) {
                        return CodeDiffViewer(
                          filePath: log.message,
                          diffContent: log.payload?['diff']?.toString() ?? log.message,
                        );
                      }

                      // Standard Telemetry Log Card
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderMetal),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: log.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.tag,
                                    style: TextStyle(
                                      color: log.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    log.rawType.toUpperCase().replaceAll('_', ' '),
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  log.timestamp,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            if (log.message.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                log.message,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(TelemetryFilter filter) {
    switch (filter) {
      case TelemetryFilter.all:
        return 'All';
      case TelemetryFilter.logs:
        return 'Agent Logs';
      case TelemetryFilter.diffs:
        return 'Diffs';
      case TelemetryFilter.terminal:
        return 'Terminal';
      case TelemetryFilter.errors:
        return 'Errors';
    }
  }

  int _getFilterCount(List<TelemetryLogItem> logs, TelemetryFilter filter) {
    if (filter == TelemetryFilter.all) return logs.length;
    return logs.where((l) => l.category == filter).length;
  }
}
