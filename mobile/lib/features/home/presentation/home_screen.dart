import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/connection_status_pill.dart';
import '../../../core/state/connection_state.dart';
import '../../../core/state/telemetry_state.dart';
import '../../approvals/application/approvals_controller.dart';
import '../../approvals/presentation/widgets/approval_detail_sheet.dart';
import '../../approvals/domain/approval_intent.dart';
import 'widgets/approval_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionStateProvider);
    final telemetry = ref.watch(telemetryProvider);
    final approvalsAsync = ref.watch(approvalsControllerProvider);

    final isConnected = connection.isLive;
    final hostName = connection.activeHostName ?? 'PREDATOR-LocalLoop';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // 1. Tactical HUD Header with Cyberpunk Status Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.all_inclusive_rounded, size: 18, color: AppColors.accent),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'LocalLoop',
                      style: AppTypography.screenTitle.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const ConnectionStatusPill(),
              ],
            ),

            const SizedBox(height: 14),

            // 2. Host Telemetry & System Radar Banner
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.laptop_windows_rounded, size: 16, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text(
                            hostName,
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? AppColors.accent.withValues(alpha: 0.12)
                              : AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isConnected
                                ? AppColors.accent.withValues(alpha: 0.3)
                                : AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          isConnected ? 'Active' : (connection.isReconnecting ? 'Reconnecting' : 'Offline'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? AppColors.accent : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniHudMetric('WORKSPACE', 'Ghost-Link'),
                      _buildMiniHudMetric('LINK', isConnected ? 'Encrypted' : 'Standby'),
                      _buildMiniHudMetric('MODE', 'Supervised'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. Tactical KPI Matrix (3 stats)
            approvalsAsync.when(
              data: (approvals) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        'APPROVALS',
                        '${approvals.length}',
                        approvals.isNotEmpty ? AppColors.warning : AppColors.accent,
                        Icons.security_rounded,
                        isAlert: approvals.isNotEmpty,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildKpiCard(
                        'ACTIVITY',
                        '${telemetry.allLogs.length}',
                        AppColors.accentCyan,
                        Icons.terminal_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildKpiCard(
                        'LATENCY',
                        connection.latencyMs != null ? '${connection.latencyMs}ms' : (isConnected ? '12ms' : 'Offline'),
                        isConnected ? AppColors.accent : AppColors.textMuted,
                        Icons.bolt_rounded,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 18),

            // 4. Security & Approvals Queue
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 16, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      'APPROVAL INBOX',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                OutlinedButton(
                  onPressed: () {
                    final mockIntent = ApprovalIntent(
                      intentId: DateTime.now().millisecondsSinceEpoch.toString(),
                      action: 'npm install',
                      target: 'express cors dotenv',
                      workingDirectory: 'E:\\Ghost-Link',
                      command: 'npm install express cors dotenv',
                      reasoning: 'Installing runtime dependencies for autonomous background agent',
                      riskLevel: 'Medium',
                      timestamp: DateTime.now(),
                    );
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => ApprovalDetailSheet(intent: mockIntent),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderMetal),
                    backgroundColor: AppColors.surfaceElevated,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 13, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'TEST APPROVAL',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Approvals Feed
            approvalsAsync.when(
              data: (approvals) {
                if (approvals.isEmpty) {
                  return GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfacePressed,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.check_circle_outline, size: 22, color: AppColors.accent),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NO PENDING APPROVALS',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'High-risk commands will request signed authorization here.',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: approvals.map((approval) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => ApprovalDetailSheet(intent: approval),
                          );
                        },
                        child: ApprovalCard(
                          title: approval.action,
                          workspace: approval.workingDirectory,
                          machine: approval.target,
                          time: 'Requires authorization',
                          onApprove: () {
                            ref.read(approvalsControllerProvider.notifier).respondToApproval(approval.intentId, true);
                          },
                          onReject: () {
                            ref.read(approvalsControllerProvider.notifier).respondToApproval(approval.intentId, false);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),

            const SizedBox(height: 20),

            // 5. Active Agent Session Quick Panel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.terminal_rounded, size: 16, color: AppColors.accentCyan),
                    const SizedBox(width: 6),
                    Text(
                      'AGENT SESSIONS',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/new-session'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.accent,
                  ),
                  child: const Text('+ LAUNCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfacePressed,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.play_arrow_outlined, size: 18, color: AppColors.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Standby Mode',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Host bridge listening for agent CLI invocations',
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/sessions'),
                    icon: const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 6. Live Activity Stream (Powered by TelemetryProvider)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'Recent Activity',
                      style: AppTypography.cardTitle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (telemetry.allLogs.isNotEmpty)
                  TextButton(
                    onPressed: () => ref.read(telemetryProvider.notifier).clear(),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: AppColors.textMuted,
                    ),
                    child: const Text('CLEAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF07090D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderMetal),
              ),
              child: telemetry.allLogs.isEmpty
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Waiting for agent activity...',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    )
                  : Column(
                      children: telemetry.allLogs.take(15).map((log) {
                        return _buildLogItem(log.timestamp, log.tag, log.message, log.color);
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniHudMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, Color color, IconData icon, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAlert ? AppColors.warning : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isAlert ? AppColors.warning : AppColors.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(String timestamp, String tag, String message, Color tagColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            timestamp,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontFamily: 'monospace'),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: tagColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
