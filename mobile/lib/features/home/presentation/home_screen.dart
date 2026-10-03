import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/state/connection_state.dart';
import '../../approvals/application/approvals_controller.dart';
import '../../approvals/presentation/widgets/approval_detail_sheet.dart';
import 'widgets/approval_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionStateProvider);
    final approvalsAsync = ref.watch(approvalsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inbox', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(
              child: _buildActiveWorkstationPill(connection),
            ),
          )
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: approvalsAsync.when(
          data: (approvals) {
            if (approvals.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: approvals.length,
              itemBuilder: (context, index) {
                final approval = approvals[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => ApprovalDetailSheet(intent: approval),
                      );
                    },
                    child: ApprovalCard(
                      title: approval.action,
                      workspace: approval.workingDirectory,
                      machine: approval.target,
                      time: 'Requires authorization',
                      onApprove: () {
                        ref.read(approvalsControllerProvider.notifier).respondToApproval(approval.intentId, true);
                      },
                      onReject: () {
                        ref.read(approvalsControllerProvider.notifier).respondToApproval(approval.intentId, false);
                      },
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
            ),
          ),
          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.danger))),
        ),
      ),
    );
  }

  Widget _buildActiveWorkstationPill(ConnectionStateModel connection) {
    final isConnected = connection.isLive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppColors.success : AppColors.warning,
              boxShadow: isConnected
                  ? [const BoxShadow(color: AppColors.successGlow, blurRadius: 4, spreadRadius: 1)]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No pending agent requests.',
            style: AppTypography.body.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
