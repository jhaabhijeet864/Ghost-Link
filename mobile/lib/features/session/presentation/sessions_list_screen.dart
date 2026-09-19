import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/status_icon.dart';
import 'widgets/session_card.dart';

class SessionsListScreen extends ConsumerStatefulWidget {
  const SessionsListScreen({super.key});

  @override
  ConsumerState<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends ConsumerState<SessionsListScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = [
    'All',
    'Active',
    'Waiting',
    'Failed',
    'Completed',
    'Cancelled',
    'Needs attention'
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Sessions',
      body: Column(
        children: [
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

          // Sessions List
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.standard),
              children: [
                SessionCard(
                  title: 'Fix timeout handling',
                  statusType: StatusType.info,
                  statusText: 'Running',
                  duration: '8m 42s',
                  workspace: 'CRM API',
                  branch: 'feature/timeouts',
                  currentActivity: 'Running integration tests',
                  lastUpdate: '12s ago',
                  onTap: () {
                    context.push('/session/mock-session-id');
                  },
                ),
                SessionCard(
                  title: 'Migrate to new architecture',
                  statusType: StatusType.warning,
                  statusText: 'Waiting',
                  duration: '2h 15m',
                  workspace: 'LocalLoop',
                  branch: 'v2-rewrite',
                  currentActivity: 'Needs approval for destructive action',
                  lastUpdate: '14m ago',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
