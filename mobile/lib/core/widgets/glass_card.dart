import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Border? customBorder;
  final Color? glowColor;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.customBorder,
    this.glowColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.metalCardGradient,
        borderRadius: BorderRadius.circular(12),
        border: customBorder ?? Border.all(
          color: glowColor != null ? glowColor!.withValues(alpha: 0.35) : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          if (glowColor != null)
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 2),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.accent.withValues(alpha: 0.08),
          highlightColor: AppColors.surfacePressed.withValues(alpha: 0.3),
          child: content,
        ),
      );
    }

    return content;
  }
}
