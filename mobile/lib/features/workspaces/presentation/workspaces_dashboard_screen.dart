import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/network/websocket_client.dart';
import 'widgets/workspace_card.dart';
import '../application/workspaces_controller.dart';

class WorkspacesDashboardScreen extends ConsumerStatefulWidget {
  final Function(int)? onNavigateTab;

  const WorkspacesDashboardScreen({
    super.key,
    this.onNavigateTab,
  });

  @override
  ConsumerState<WorkspacesDashboardScreen> createState() => _WorkspacesDashboardScreenState();
}

class _WorkspacesDashboardScreenState extends ConsumerState<WorkspacesDashboardScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Clean', 'Modified'];

  @override
  Widget build(BuildContext context) {
    final workspacesAsyncValue = ref.watch(workspacesControllerProvider);
    final isConnected = WebSocketClient().status == ConnectionStatus.connected;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clean Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projects',
                        style: AppTypography.screenTitle.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Indexed repositories on host workstation',
                        style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: workspacesAsyncValue.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                          )
                        : const Icon(Icons.refresh_rounded, color: AppColors.accent, size: 22),
                    tooltip: 'Refresh Workspaces',
                    onPressed: () => ref.read(workspacesControllerProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),

            // Host Context Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dns_rounded, size: 16, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Text(
                          'PREDATOR-LocalLoop',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      isConnected ? 'Online' : 'Disconnected',
                      style: AppTypography.caption.copyWith(
                        color: isConnected ? AppColors.accent : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Filter Tabs
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = filter == _selectedFilter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = filter),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.surfacePressed : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.accent : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.accent : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Workspace List
            Expanded(
              child: workspacesAsyncValue.when(
                data: (workspaces) {
                  final filtered = _selectedFilter == 'All'
                      ? workspaces
                      : workspaces.where((w) => w.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.folder_off_outlined, size: 36, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                isConnected ? 'No Projects Found' : 'Connect Host to View Projects',
                                style: AppTypography.cardTitle,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isConnected
                                    ? 'Tap the refresh icon above to scan host directories.'
                                    : 'Ensure LocalLoop.Service is running on your workstation.',
                                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref.read(workspacesControllerProvider.notifier).refresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final workspace = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: WorkspaceCard(
                            title: workspace.name,
                            branch: workspace.branch,
                            modifiedFiles: workspace.modifiedFiles,
                            failingTests: workspace.failingTests,
                            activeSessions: workspace.activeSessions,
                            machine: workspace.machineId.isNotEmpty ? workspace.machineId : 'PREDATOR-LocalLoop',
                            onTap: () {
                              context.push('/workspace/${workspace.id}');
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
                error: (error, _) => ErrorState(message: error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
