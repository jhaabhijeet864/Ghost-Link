import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radii.dart';
import 'status_icon.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;

    switch (type) {
      case StatusType.success:
        bgColor = AppColors.success.withOpacity(0.15);
        fgColor = AppColors.success;
        break;
      case StatusType.warning:
        bgColor = AppColors.warning.withOpacity(0.15);
        fgColor = AppColors.warning;
        break;
      case StatusType.danger:
        bgColor = AppColors.danger.withOpacity(0.15);
        fgColor = AppColors.danger;
        break;
      case StatusType.info:
        bgColor = AppColors.info.withOpacity(0.15);
        fgColor = AppColors.info;
        break;
      case StatusType.neutral:
        bgColor = AppColors.surfaceElevated;
        fgColor = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.micro,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadii.compact),
        border: Border.all(
          color: type == StatusType.neutral ? AppColors.border : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(width: AppSpacing.micro),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: fgColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
