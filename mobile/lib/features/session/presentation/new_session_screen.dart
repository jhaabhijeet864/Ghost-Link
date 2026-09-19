import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_scaffold.dart';
import 'session_review_screen.dart';

class NewSessionScreen extends ConsumerStatefulWidget {
  const NewSessionScreen({super.key});

  @override
  ConsumerState<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends ConsumerState<NewSessionScreen> {
  final TextEditingController _instructionController = TextEditingController();
  bool _askBeforeRiskyActions = true;

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'New coding session',
      showBackButton: true,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.standard),
        children: [
          // Selections
          _buildDropdownSection('Machine', 'Rajesh-Workstation'),
          const SizedBox(height: AppSpacing.standard),
          _buildDropdownSection('Workspace', 'CRM API · feature/timeouts'),
          const SizedBox(height: AppSpacing.standard),
          _buildDropdownSection('Agent or adapter', 'Antigravity Desktop'),
          const SizedBox(height: AppSpacing.large),

          // Instruction Field
          Text('Instruction', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.small),
          TextField(
            controller: _instructionController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Describe what you want the agent to do...',
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic, color: AppColors.primary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.large),

          // Policy
          Text('Execution policy', style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.small),
          SwitchListTile(
            title: Text('Ask before risky actions', style: AppTypography.body),
            subtitle: Text(
                'Agent will pause for approval before executing commands like git push or rm.',
                style: AppTypography.caption),
            value: _askBeforeRiskyActions,
            onChanged: (val) => setState(() => _askBeforeRiskyActions = val),
            activeColor: AppColors.accent,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.large),

          // Action
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
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SessionReviewScreen(
                      instruction: _instructionController.text,
                    ),
                  ),
                );
              },
              child: const Text('Review and start'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(height: AppSpacing.micro),
        Container(
          padding: const EdgeInsets.all(AppSpacing.standard),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: AppTypography.body),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ],
    );
  }
}
