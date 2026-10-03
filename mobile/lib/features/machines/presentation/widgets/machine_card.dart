import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';

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
    final statusColor = isOnline ? AppColors.accent : AppColors.textMuted;
    final statusText = isOnline ? 'ONLINE' : 'OFFLINE';

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
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: AppTypography.cardTitle.copyWith(fontSize: 14, fontFamily: 'monospace'),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$activeSessions active sessions • Desktop Bridge ready',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
              ),
              Text(
                lastSync,
                style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
