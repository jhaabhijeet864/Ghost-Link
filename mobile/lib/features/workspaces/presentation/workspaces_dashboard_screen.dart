import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/error_state.dart';
import 'widgets/workspace_card.dart';
import '../application/workspaces_controller.dart';

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
    final workspacesAsyncValue = ref.watch(workspacesControllerProvider);

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
          child: workspacesAsyncValue.when(
            data: (workspaces) {
              if (workspaces.isEmpty) {
                return Center(
                  child: Text('No workspaces found', style: AppTypography.secondary),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(workspacesControllerProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.standard),
                  itemCount: workspaces.length,
                  itemBuilder: (context, index) {
                    final workspace = workspaces[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.standard),
                      child: WorkspaceCard(
                        title: workspace.name,
                        branch: workspace.branch,
                        modifiedFiles: workspace.modifiedFiles,
                        failingTests: workspace.failingTests,
                        activeSessions: workspace.activeSessions,
                        machine: workspace.machineId.isNotEmpty ? workspace.machineId : 'Rajesh-Workstation',
                        onTap: () {
                          context.push('/workspace/${workspace.id}');
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => ErrorState(message: error.toString()),
          ),
        ),
      ],
    );
  }
}
