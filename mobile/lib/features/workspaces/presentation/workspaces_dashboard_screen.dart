import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import 'widgets/workspace_card.dart';

class WorkspacesDashboardScreen extends ConsumerStatefulWidget {
  final Function(int) onNavigateTab;

  const WorkspacesDashboardScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  ConsumerState<WorkspacesDashboardScreen> createState() =>
      _WorkspacesDashboardScreenState();
}

class _WorkspacesDashboardScreenState
    extends ConsumerState<WorkspacesDashboardScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Healthy', 'Needs attention', 'Active'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App Bar equivalent
        Padding(
          padding: const EdgeInsets.all(AppSpacing.standard),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Workspaces',
                style: AppTypography.screenTitle,
              ),
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.textPrimary),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Filters
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.standard),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = filter == _selectedFilter;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.small),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = filter);
                  },
                  backgroundColor: AppColors.surfaceElevated,
                  selectedColor: AppColors.surfacePressed,
                  labelStyle: AppTypography.body.copyWith(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.border : Colors.transparent,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.standard),

        // Active Workstation Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.standard),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.standard),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('Active Machine: Rajesh-Workstation', style: AppTypography.body),
          ),
        ),

        const SizedBox(height: AppSpacing.standard),

        // Workspace List
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.standard),
            children: [
              WorkspaceCard(
                title: 'CRM API',
                branch: 'feature/timeouts',
                modifiedFiles: 7,
                failingTests: 2,
                activeSessions: 1,
                machine: 'Rajesh-Workstation',
                onTap: () {
                  context.push('/workspace/crm-api');
                },
              ),
              WorkspaceCard(
                title: 'LocalLoop.Client',
                branch: 'main',
                modifiedFiles: 0,
                failingTests: 0,
                activeSessions: 0,
                machine: 'Rajesh-Workstation',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
