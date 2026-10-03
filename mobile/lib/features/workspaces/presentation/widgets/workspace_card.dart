import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';

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
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder_outlined, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: AppTypography.cardTitle.copyWith(fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfacePressed,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fork_right_rounded, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 3),
                    Text(
                      branch,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$modifiedFiles changed files',
                  style: const TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'HOST: $machine',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
