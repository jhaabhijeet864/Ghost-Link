import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class TestsTab extends StatelessWidget {
  const TestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.standard),
      children: [
        // Header
        Text('Integration tests', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.small),
        Row(
          children: [
            _buildStat('Failed', '2', AppColors.danger),
            const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
            _buildStat('Passed', '47', AppColors.success),
            const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
            _buildStat('Skipped', '1', AppColors.neutral),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        Text('Duration: 1m 12s', style: AppTypography.caption),
        
        const SizedBox(height: AppSpacing.large),
        
        // Failures
        Text('Failures', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.small),
        _buildFailureRow('test/integration/websocket_test.dart', 'Timeout expected 2000ms but got 5000ms'),
        const SizedBox(height: AppSpacing.small),
        _buildFailureRow('test/integration/auth_test.dart', 'Expected HandshakeResult.success but got HandshakeResult.timeout'),
        
        const SizedBox(height: AppSpacing.large),
        
        // Actions
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.help_outline),
          label: const Text('Explain failures'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.info,
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.refresh),
          label: const Text('Rerun failed tests'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceElevated,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return RichText(
      text: TextSpan(
        style: AppTypography.body,
        children: [
          TextSpan(text: '$label ', style: const TextStyle(color: AppColors.textSecondary)),
          TextSpan(text: value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFailureRow(String path, String error) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.standard),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(path, style: AppTypography.code.copyWith(fontSize: 12, color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.small),
          Text(error, style: AppTypography.body.copyWith(color: AppColors.danger)),
        ],
      ),
    );
  }
}
