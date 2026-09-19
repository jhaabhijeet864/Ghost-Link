import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class EvidenceTab extends StatelessWidget {
  const EvidenceTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.standard),
      children: [
        // Warning Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.standard),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              const SizedBox(width: AppSpacing.standard),
              Expanded(
                child: Text(
                  'Evidence is not proof of execution. UI Automation fallback may have encountered unexpected screen states.',
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        
        Text('Execution Details', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.standard),
        
        _buildDetailRow('Target Application', 'Google Chrome'),
        _buildDetailRow('Target Window', 'CRM Dashboard - 1024x768'),
        _buildDetailRow('Automation Method', 'FlaUI UIA3'),
        _buildDetailRow('Action', 'Click [Submit] button'),
        _buildDetailRow('Verification', 'DOM Element Visible'),
        _buildDetailRow('Confidence', '94%'),
        _buildDetailRow('Timestamp', '2023-10-25 14:32:01 UTC'),
        
        const SizedBox(height: AppSpacing.large),
        Text('Screenshot', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.small),
        
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image, size: 48, color: AppColors.neutral),
                const SizedBox(height: AppSpacing.small),
                Text('Screenshot not available in mock mode', style: AppTypography.caption),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: AppTypography.body.copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: AppTypography.body.copyWith(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
