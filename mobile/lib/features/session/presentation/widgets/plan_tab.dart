import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class PlanTab extends StatelessWidget {
  const PlanTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.standard),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Execution Plan', style: AppTypography.sectionTitle),
            Text('Updated 2m ago', style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        
        _buildPlanStep(
          text: 'Inspect timeout configuration',
          status: _StepStatus.completed,
          isLast: false,
        ),
        _buildPlanStep(
          text: 'Identify failing request path',
          status: _StepStatus.completed,
          isLast: false,
        ),
        _buildPlanStep(
          text: 'Modify retry handling',
          status: _StepStatus.inProgress,
          isLast: false,
        ),
        _buildPlanStep(
          text: 'Run unit tests',
          status: _StepStatus.pending,
          isLast: false,
        ),
        _buildPlanStep(
          text: 'Run integration tests',
          status: _StepStatus.pending,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildPlanStep({
    required String text,
    required _StepStatus status,
    required bool isLast,
  }) {
    IconData icon;
    Color iconColor;
    Color textColor;

    switch (status) {
      case _StepStatus.completed:
        icon = Icons.check_circle;
        iconColor = AppColors.success;
        textColor = AppColors.textSecondary;
        break;
      case _StepStatus.inProgress:
        icon = Icons.radio_button_checked;
        iconColor = AppColors.accent;
        textColor = AppColors.textPrimary;
        break;
      case _StepStatus.pending:
        icon = Icons.radio_button_unchecked;
        iconColor = AppColors.neutral;
        textColor = AppColors.textMuted;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Icon(icon, size: 20, color: iconColor),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSpacing.large,
                top: 2,
              ),
              child: Text(
                text,
                style: AppTypography.body.copyWith(
                  color: textColor,
                  fontWeight: status == _StepStatus.inProgress ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepStatus { completed, inProgress, pending }
