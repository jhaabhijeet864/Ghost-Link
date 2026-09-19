import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_scaffold.dart';

class SessionReviewScreen extends ConsumerWidget {
  final String instruction;

  const SessionReviewScreen({
    super.key,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'Review session',
      showBackButton: true,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.standard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('Target', 'Rajesh-Workstation · CRM API'),
            const SizedBox(height: AppSpacing.standard),
            _buildSection('Branch', 'feature/timeouts'),
            const SizedBox(height: AppSpacing.standard),
            _buildSection('Adapter', 'Antigravity Desktop'),
            const SizedBox(height: AppSpacing.large),

            Text('Instruction', style: AppTypography.caption),
            const SizedBox(height: AppSpacing.micro),
            Text(
              instruction.isEmpty ? 'No instruction provided' : instruction,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.large),

            Text('Constraints', style: AppTypography.caption),
            const SizedBox(height: AppSpacing.micro),
            Text('Do not commit or push.', style: AppTypography.body),
            const SizedBox(height: AppSpacing.large),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSection(
                    'Potential operations', 'Modify files · Run tests'),
                _buildSection('Risk', 'Medium', textColor: AppColors.warning),
              ],
            ),
            const Spacer(),

            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  // Dispatch logic would go here
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Start session'),
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Edit', style: AppTypography.button),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String label, String value,
      {Color textColor = AppColors.textPrimary}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: AppSpacing.micro),
        Text(value, style: AppTypography.body.copyWith(color: textColor)),
      ],
    );
  }
}
