import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/status_icon.dart';

class SessionCard extends StatelessWidget {
  final String title;
  final StatusType statusType;
  final String statusText;
  final String duration;
  final String workspace;
  final String branch;
  final String currentActivity;
  final String lastUpdate;
  final VoidCallback onTap;

  const SessionCard({
    super.key,
    required this.title,
    required this.statusType,
    required this.statusText,
    required this.duration,
    required this.workspace,
    required this.branch,
    required this.currentActivity,
    required this.lastUpdate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.standard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.standard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.cardTitle,
              ),
              const SizedBox(height: AppSpacing.micro),
              Row(
                children: [
                  StatusIcon(type: statusType, size: 14),
                  const SizedBox(width: AppSpacing.micro),
                  Text(
                    '$statusText · $duration',
                    style: AppTypography.caption,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                '$workspace · $branch',
                style: AppTypography.secondary,
              ),
              const SizedBox(height: AppSpacing.micro),
              Text(
                currentActivity,
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Last update $lastUpdate',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
