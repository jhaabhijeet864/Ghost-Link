import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/status_icon.dart';

class ApprovalCard extends StatefulWidget {
  final String title;
  final String machine;
  final String workspace;
  final String time;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const ApprovalCard({
    super.key,
    required this.title,
    required this.machine,
    required this.workspace,
    required this.time,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<ApprovalCard> {
  bool _isHolding = false;
  
  void _handleHoldStart(TapDownDetails details) {
    setState(() => _isHolding = true);
    // In a real implementation, we'd start a timer for face ID / long press
  }

  void _handleHoldEnd(TapUpDetails details) {
    setState(() => _isHolding = false);
    widget.onApprove();
  }
  
  void _handleHoldCancel() {
    setState(() => _isHolding = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.standard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const StatusBadge(
                  label: 'Needs approval',
                  type: StatusType.warning,
                  icon: Icons.shield,
                ),
                Text(
                  widget.time,
                  style: AppTypography.caption,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              widget.title,
              style: AppTypography.cardTitle,
            ),
            const SizedBox(height: AppSpacing.micro),
            Text(
              '${widget.workspace} · ${widget.machine}',
              style: AppTypography.secondary,
            ),
            const SizedBox(height: AppSpacing.standard),
            Container(
              padding: const EdgeInsets.all(AppSpacing.small),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadii.compact),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'High Risk Action', // Example content
                style: AppTypography.code,
              ),
            ),
            const SizedBox(height: AppSpacing.standard),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.standard),
                Expanded(
                  child: GestureDetector(
                    onTapDown: _handleHoldStart,
                    onTapUp: _handleHoldEnd,
                    onTapCancel: _handleHoldCancel,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isHolding ? AppColors.success : AppColors.surfacePressed,
                        borderRadius: BorderRadius.circular(AppRadii.button),
                        border: Border.all(color: AppColors.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Hold to Approve',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _isHolding ? AppColors.background : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
