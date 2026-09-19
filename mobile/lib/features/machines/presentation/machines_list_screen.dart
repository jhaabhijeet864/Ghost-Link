import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import 'widgets/machine_card.dart';

class MachinesListScreen extends StatelessWidget {
  final Function(int) onNavigateTab;

  const MachinesListScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.standard),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Machines', style: AppTypography.screenTitle),
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.textPrimary),
                onPressed: () {
                  // Navigate to pairing flow
                  // For now we assume the router handles this or we push it
                  Navigator.of(context).pushNamed('/pairing');
                },
                tooltip: 'Pair new machine',
              ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.standard),
            children: [
              MachineCard(
                name: 'Rajesh-Workstation',
                isOnline: true,
                isBridgeReady: true,
                activeSessions: 2,
                lastSync: 'just now',
                onTap: () {
                  // Navigate to machine details
                },
              ),
              const SizedBox(height: AppSpacing.standard),
              MachineCard(
                name: 'MacBook-Pro-M1',
                isOnline: false,
                isBridgeReady: false,
                activeSessions: 0,
                lastSync: '3 days ago',
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.standard),
              // Revoked/Attention card mock
              Container(
                padding: const EdgeInsets.all(AppSpacing.standard),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                    const SizedBox(width: AppSpacing.standard),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Legacy-Server', style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                          Text('Access revoked. Re-pairing required.', style: AppTypography.caption.copyWith(color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
