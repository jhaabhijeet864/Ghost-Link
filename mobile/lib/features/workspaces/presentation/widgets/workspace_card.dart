import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class WorkspaceCard extends StatelessWidget {
  final String title;
  final String branch;
  final int modifiedFiles;
  final int failingTests;
  final int activeSessions;
  final String machine;
  final VoidCallback onTap;

  const WorkspaceCard({
    super.key,
    required this.title,
    required this.branch,
    required this.modifiedFiles,
    required this.failingTests,
    required this.activeSessions,
    required this.machine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.standard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0), // Should match AppRadii.card
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
              Text(
                '$branch · $modifiedFiles modified files',
                style:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.micro),
              Row(
                children: [
                  Icon(
                    failingTests > 0
                        ? Icons.error_outline
                        : Icons.check_circle_outline,
                    size: 16,
                    color:
                        failingTests > 0 ? AppColors.danger : AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.micro),
                  Text(
                    failingTests > 0
                        ? '$failingTests failing tests'
                        : 'All tests passing',
                    style: AppTypography.caption.copyWith(
                      color: failingTests > 0
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.standard),
                  if (activeSessions > 0) ...[
                    const Icon(
                      Icons.play_circle_outline,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppSpacing.micro),
                    Text(
                      '$activeSessions active session${activeSessions > 1 ? 's' : ''}',
                      style:
                          AppTypography.caption.copyWith(color: AppColors.info),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                machine,
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
