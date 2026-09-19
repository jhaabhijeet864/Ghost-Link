import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/approval_intent.dart';
import '../../application/approvals_controller.dart';
import 'hold_to_approve_button.dart';

class ApprovalDetailSheet extends ConsumerStatefulWidget {
  final ApprovalIntent intent;

  const ApprovalDetailSheet({
    super.key,
    required this.intent,
  });

  @override
  ConsumerState<ApprovalDetailSheet> createState() => _ApprovalDetailSheetState();
}

class _ApprovalDetailSheetState extends ConsumerState<ApprovalDetailSheet> {
  late Timer _timer;
  int _secondsRemaining = 120; // 2 minutes

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer.cancel();
        _rejectAndClose();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _rejectAndClose() {
    ref.read(approvalsControllerProvider.notifier).respondToApproval(widget.intent.intentId, false);
    Navigator.of(context).pop();
  }

  void _approveAndClose() async {
    await ref.read(approvalsControllerProvider.notifier).respondToApproval(widget.intent.intentId, true);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _secondsRemaining <= 30;
    
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.standard,
        right: AppSpacing.standard,
        top: AppSpacing.standard,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.standard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Approval Request',
                style: AppTypography.cardTitle,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUrgent ? AppColors.danger.withValues(alpha: 0.1) : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _formatTime(_secondsRemaining),
                  style: TextStyle(
                    color: isUrgent ? AppColors.danger : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          
          Text(
            widget.intent.action,
            style: AppTypography.screenTitle,
          ),
          const SizedBox(height: AppSpacing.standard),
          
          _buildInfoRow('Target', widget.intent.target),
          _buildInfoRow('Directory', widget.intent.workingDirectory),
          
          const SizedBox(height: AppSpacing.large),
          Text('Command to Execute', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.small),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.standard),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117), // GitHub dark theme background
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              widget.intent.command,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.large),
          Text('Reasoning', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.small),
          Text(
            widget.intent.reasoning,
            style: AppTypography.body,
          ),
          
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _rejectAndClose,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: AppSpacing.standard),
              Expanded(
                flex: 2,
                child: HoldToApproveButton(
                  onApproved: _approveAndClose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTypography.secondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
