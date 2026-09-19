import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_scaffold.dart';

class WorkspaceDetailScreen extends StatelessWidget {
  final String workspaceId;

  const WorkspaceDetailScreen({
    super.key,
    required this.workspaceId,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBackButton: true,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.standard),
        children: [
          // Header
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CRM API', style: AppTypography.display),
              const SizedBox(height: AppSpacing.small),
              Text('D:\\Projects\\crm-api', style: AppTypography.body.copyWith(color: AppColors.textMuted)),
              Text('feature/timeouts', style: AppTypography.code.copyWith(color: AppColors.accent)),
            ],
          ),
          
          const SizedBox(height: AppSpacing.large),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/new-session');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start session'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.standard),
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          
          _buildSectionTitle('Health summary'),
          _buildDetailRow('Modified files', '7', AppColors.warning),
          _buildDetailRow('Failing tests', '2', AppColors.danger),
          
          const SizedBox(height: AppSpacing.large),
          _buildSectionTitle('Active session'),
          _buildActionRow(Icons.terminal, 'Fix timeout handling', onTap: () {
            context.push('/session/mock-session-id');
          }),
          
          const SizedBox(height: AppSpacing.large),
          _buildSectionTitle('Recent sessions'),
          _buildActionRow(Icons.history, 'Update dependencies (Completed)'),
          
          const SizedBox(height: AppSpacing.large),
          _buildSectionTitle('Review'),
          _buildActionRow(Icons.code, 'Review diff'),
          _buildActionRow(Icons.bug_report, 'View tests'),
          
          const SizedBox(height: AppSpacing.large),
          _buildSectionTitle('Configuration'),
          _buildActionRow(Icons.policy, 'Configure policies'),
          _buildActionRow(Icons.api, 'Change adapter'),
          _buildActionRow(Icons.edit, 'Rename workspace'),
          _buildActionRow(Icons.archive, 'Archive workspace', isDanger: true),
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

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body.copyWith(color: AppColors.textMuted)),
          Text(value, style: AppTypography.body.copyWith(color: valueColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String label, {VoidCallback? onTap, bool isDanger = false}) {
    final color = isDanger ? AppColors.danger : AppColors.textPrimary;
    return InkWell(
      onTap: onTap ?? () {},
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
