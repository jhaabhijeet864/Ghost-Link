import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum StatusType {
  success,
  warning,
  danger,
  info,
  neutral,
}

class StatusIcon extends StatelessWidget {
  final StatusType type;
  final IconData? customIcon;
  final double size;

  const StatusIcon({
    super.key,
    required this.type,
    this.customIcon,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData iconData;

    switch (type) {
      case StatusType.success:
        color = AppColors.success;
        iconData = customIcon ?? Icons.check_circle;
        break;
      case StatusType.warning:
        color = AppColors.warning;
        iconData = customIcon ?? Icons.warning;
        break;
      case StatusType.danger:
        color = AppColors.danger;
        iconData = customIcon ?? Icons.error;
        break;
      case StatusType.info:
        color = AppColors.info;
        iconData = customIcon ?? Icons.info;
        break;
      case StatusType.neutral:
        color = AppColors.neutral;
        iconData = customIcon ?? Icons.help;
        break;
    }

    return Icon(
      iconData,
      color: color,
      size: size,
    );
  }
}
