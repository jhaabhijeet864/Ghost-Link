import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class TimelineTab extends StatelessWidget {
  const TimelineTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.standard),
      children: [
        _buildTimelineEvent(
          time: '09:00 AM',
          icon: Icons.person,
          title: 'User Prompt',
          description: '"Fix the timeout issue in the CRM API"',
          color: AppColors.info,
          isFirst: true,
        ),
        _buildTimelineEvent(
          time: '09:01 AM',
          icon: Icons.smart_toy,
          title: 'Agent Action',
          description: 'Started session on workspace CRM-API',
          color: AppColors.accent,
        ),
        _buildTimelineEvent(
          time: '09:05 AM',
          icon: Icons.code,
          title: 'File Change',
          description: 'Modified lib/api/client.ts',
          color: AppColors.warning,
        ),
        _buildTimelineEvent(
          time: '09:06 AM',
          icon: Icons.bug_report,
          title: 'Test Failed',
          description: 'Integration test failed due to timeout assertion.',
          color: AppColors.danger,
        ),
        _buildTimelineEvent(
          time: '09:10 AM',
          icon: Icons.check_circle,
          title: 'Approval Required',
          description: 'Agent requested permission to push code.',
          color: AppColors.success,
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineEvent({
    required String time,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: AppSpacing.standard),
          // Node & Line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 2, height: 8, color: AppColors.border),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.standard),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : AppSpacing.large,
                top: 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
