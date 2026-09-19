import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/status_icon.dart';

class MachineCard extends StatelessWidget {
  final String name;
  final bool isOnline;
  final bool isBridgeReady;
  final int activeSessions;
  final String lastSync;
  final VoidCallback onTap;

  const MachineCard({
    super.key,
    required this.name,
    required this.isOnline,
    required this.isBridgeReady,
    required this.activeSessions,
    required this.lastSync,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOnline ? AppColors.success : AppColors.textMuted;
    final statusText = isOnline ? 'Online' : 'Offline';
    final bridgeText = isBridgeReady ? 'Desktop bridge ready' : 'Bridge disconnected';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.standard),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: AppTypography.screenTitle.copyWith(fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.shield,
                  color: isOnline ? AppColors.success : AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Text(
                  '$statusText · $bridgeText',
                  style: AppTypography.body.copyWith(
                    color: isOnline ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$activeSessions active sessions',
                  style: AppTypography.caption,
                ),
                Text(
                  'Last sync $lastSync',
                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
