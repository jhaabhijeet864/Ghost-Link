import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/connection_status_pill.dart';
import '../../../core/state/connection_state.dart';
import '../application/machines_controller.dart';
import 'widgets/machine_card.dart';

class MachinesListScreen extends ConsumerWidget {
  final Function(int)? onNavigateTab;

  const MachinesListScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machinesAsyncValue = ref.watch(machinesControllerProvider);
    final connection = ref.watch(connectionStateProvider);
    final isConnected = connection.isLive;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // 1. Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WORKSTATIONS // CLUSTER',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Host machines executing background AI loops',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/pairing'),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: const Text('PAIR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 2. Zeroconf Discovery Banner
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfacePressed,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.radar_rounded, size: 18, color: AppColors.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'mDNS Zeroconf Discovery',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'LAN',
                                style: TextStyle(fontSize: 9, color: AppColors.accent, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Zero-config local mesh active',
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const ConnectionStatusPill(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Active Host Workstation Card (Always present / detected)
            Text(
              'DISCOVERED & ACTIVE HOSTS',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),

            GlassCard(
              glowColor: isConnected ? AppColors.accent : null,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfacePressed,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.laptop_windows_rounded, size: 22, color: AppColors.accent),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'PREDATOR-LocalLoop',
                                    style: AppTypography.cardTitle.copyWith(fontSize: 15, fontFamily: 'monospace'),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isConnected ? AppColors.accent : AppColors.warning,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Windows 11 Pro • x64 Architecture',
                                style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfacePressed,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.borderMetal),
                        ),
                        child: Text(
                          isConnected ? 'ACTIVE' : 'STANDBY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? AppColors.accent : AppColors.textMuted,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailSnippet('LINK', 'Encrypted Tunnel'),
                      _buildDetailSnippet('CONTROL', 'Direct Core'),
                      _buildDetailSnippet('STATUS', 'Ready'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pinging PREADATOR-LocalLoop... Host responsive (14ms)'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.bolt, size: 14, color: AppColors.accent),
                          label: const Text('TEST PING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.borderMetal),
                            foregroundColor: AppColors.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/pairing'),
                          icon: const Icon(Icons.sync_rounded, size: 14),
                          label: const Text('RE-PAIR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfacePressed,
                            foregroundColor: AppColors.accent,
                            side: const BorderSide(color: AppColors.borderMetal),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. Paired Machines from Storage
            machinesAsyncValue.when(
              data: (machines) {
                if (machines.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OTHER PAIRED WORKSTATIONS (${machines.length})',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...machines.map((machine) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MachineCard(
                          name: machine.name,
                          isOnline: machine.status == 'Healthy' || machine.status == 'Active',
                          isBridgeReady: true,
                          activeSessions: 0,
                          lastSync: 'Sync available',
                          onTap: () {
                            context.push('/machine/${machine.id}');
                          },
                        ),
                      );
                    }),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSnippet(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontFamily: 'monospace', fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace', fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
