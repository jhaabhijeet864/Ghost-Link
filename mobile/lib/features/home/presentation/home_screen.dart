import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import 'widgets/approval_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.standard),
      children: [
        Text(
          'Good evening',
          style: AppTypography.display,
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          '1 machine online',
          style: AppTypography.secondary.copyWith(color: AppColors.success),
        ),
        const SizedBox(height: AppSpacing.large),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Needs attention',
              style: AppTypography.sectionTitle,
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        
        ApprovalCard(
          title: 'Install dependency',
          workspace: 'CRM API',
          machine: 'Rajesh-Workstation',
          time: 'Requested 2m ago',
          onApprove: () {},
          onReject: () {},
        ),
        
        const SizedBox(height: AppSpacing.large),
        Text(
          'Active sessions',
          style: AppTypography.sectionTitle,
        ),
        const SizedBox(height: AppSpacing.small),
        // Empty state for now
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Text(
              'No active coding sessions',
              style: AppTypography.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
