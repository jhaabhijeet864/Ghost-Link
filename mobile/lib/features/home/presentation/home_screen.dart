import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/pulsing_badge.dart';
import '../../../core/network/websocket_client.dart';
import '../../approvals/application/approvals_controller.dart';
import '../../approvals/presentation/widgets/approval_detail_sheet.dart';
import '../../approvals/domain/approval_intent.dart';
import 'widgets/approval_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approvalsAsync = ref.watch(approvalsControllerProvider);
    final wsClient = WebSocketClient();
    final isConnected = wsClient.status == ConnectionStatus.connected;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.8, -0.9),
            radius: 1.2,
            colors: [
              Color(0x266366F1), // Indigo subtle glow
              Color(0x00090D14),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Top Bar with Brand & Live Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.all_inclusive_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'LocalLoop',
                        style: AppTypography.screenTitle.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  ValueListenableBuilder<int?>(
                    valueListenable: wsClient.latencyNotifier,
                    builder: (context, latency, _) {
                      return PulsingBadge(
                        label: isConnected ? 'Host Online ${latency != null ? '• ${latency}ms' : ''}' : 'Connecting...',
                        color: isConnected ? AppColors.success : AppColors.warning,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Hero Greeting Card
              GlassCard(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2638), Color(0xFF111724)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                glowColor: AppColors.accent,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: AppTypography.display.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AI coding agents active on local host. Ready to supervise and approve high-risk actions.',
                      style: AppTypography.secondary.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // KPI Metrics Grid (3 Stats)
              approvalsAsync.when(
                data: (approvals) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Pending',
                          value: '${approvals.length}',
                          icon: Icons.shield_outlined,
                          color: approvals.isNotEmpty ? AppColors.warning : AppColors.accentCyan,
                          glow: approvals.isNotEmpty,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Sessions',
                          value: '0',
                          icon: Icons.terminal_rounded,
                          color: AppColors.accentLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Machines',
                          value: '1',
                          icon: Icons.dns_rounded,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),

              // Section 1: Approvals / Needs Attention
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_rounded, size: 18, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text(
                        'Needs Attention',
                        style: AppTypography.sectionTitle,
                      ),
                    ],
                  ),
                  approvalsAsync.maybeWhen(
                    data: (approvals) => approvals.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${approvals.length} pending',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Approvals Content
              approvalsAsync.when(
                data: (approvals) {
                  if (approvals.isEmpty) {
                    return GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_user_outlined,
                              size: 32,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'All Loops Nominal',
                            style: AppTypography.cardTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No agent actions currently require manual confirmation.',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              // Send demo approval into the controller for instant visual testing
                              final mockIntent = ApprovalIntent(
                                intentId: DateTime.now().millisecondsSinceEpoch.toString(),
                                action: 'install',
                                target: 'npm packages',
                                workingDirectory: 'E:\\Ghost-Link',
                                command: 'npm install express cors dotenv',
                                reasoning: 'Adding server middleware packages for real-time agent bridge',
                                riskLevel: 'Medium',
                                timestamp: DateTime.now(),
                              );
                              ref.read(approvalsControllerProvider.notifier).respondToApproval('test-intent', false);
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => ApprovalDetailSheet(intent: mockIntent),
                              );
                            },
                            icon: const Icon(Icons.bolt_rounded, size: 16, color: AppColors.accentLight),
                            label: const Text(
                              'Test Approval Flow',
                              style: TextStyle(color: AppColors.accentLight, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.borderHighlight),
                              backgroundColor: AppColors.accent.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: approvals.map((approval) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
                            time: 'Needs your review',
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
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),

              const SizedBox(height: 24),

              // Section 2: Active Sessions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal_rounded, size: 18, color: AppColors.accentLight),
                      const SizedBox(width: 8),
                      Text(
                        'Active Sessions',
                        style: AppTypography.sectionTitle,
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/sessions'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentLight,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View all', style: TextStyle(fontSize: 13)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              GlassCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.developer_mode_rounded,
                        size: 24,
                        color: AppColors.accentLight,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No Active Sessions',
                            style: AppTypography.cardTitle.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Launch a new agent task or prompt from mobile',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/new-session'),
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentLight),
                      tooltip: 'New Session',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section 3: Connected Host Workstations
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dns_rounded, size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Text(
                        'Connected Machines',
                        style: AppTypography.sectionTitle,
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/machines'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentLight,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Manage', style: TextStyle(fontSize: 13)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.desktop_windows_rounded, color: AppColors.success, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'PREDATOR-LocalLoop',
                                style: AppTypography.cardTitle.copyWith(fontSize: 15),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Windows 11 • Local WebSocket (8080)',
                            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool glow = false,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      glowColor: glow ? color : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: color),
              if (glow)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color, blurRadius: 6),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.screenTitle.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
