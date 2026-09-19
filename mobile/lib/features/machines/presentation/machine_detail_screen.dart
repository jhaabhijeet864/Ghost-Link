import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_scaffold.dart';
import 'widgets/machine_card.dart';

class MachineDetailScreen extends StatelessWidget {
  final String machineId;

  const MachineDetailScreen({
    super.key,
    required this.machineId,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Machine Detail',
      showBackButton: true,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.standard),
        children: [
          MachineCard(
            name: 'Rajesh-Workstation',
            isOnline: true,
            isBridgeReady: true,
            activeSessions: 2,
            lastSync: 'just now',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.large),
          
          _buildSectionTitle('Overview'),
          _buildDetailRow('OS', 'Windows 11 Pro'),
          _buildDetailRow('LocalLoop Bridge', 'v1.2.4 (Up to date)'),
          _buildDetailRow('IP Address', '192.168.1.144'),
          
          const SizedBox(height: AppSpacing.large),
          _buildSectionTitle('Active Sessions (2)'),
          _buildActionRow(Icons.terminal, 'CRM API (feature/timeouts)'),
          _buildActionRow(Icons.terminal, 'LocalLoop (master)'),
          
          const SizedBox(height: AppSpacing.large),
          _buildSectionTitle('Actions'),
          _buildActionRow(Icons.health_and_safety, 'Run Diagnostics'),
          _buildActionRow(Icons.edit, 'Rename Machine'),
          _buildActionRow(Icons.notifications_active, 'Configure Notifications'),
          
          const SizedBox(height: AppSpacing.large),
          _buildSectionTitle('Danger Zone'),
          _buildActionRow(Icons.block, 'Revoke Phone Access', isDanger: true),
          _buildActionRow(Icons.delete_forever, 'Remove Machine Completely', isDanger: true),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Text(title, style: AppTypography.sectionTitle),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body.copyWith(color: AppColors.textMuted)),
          Text(value, style: AppTypography.body.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String label, {bool isDanger = false}) {
    final color = isDanger ? AppColors.danger : AppColors.textPrimary;
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.standard),
            Text(label, style: AppTypography.body.copyWith(color: color)),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
