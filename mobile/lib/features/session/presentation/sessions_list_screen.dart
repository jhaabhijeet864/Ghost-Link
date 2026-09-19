import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_icon.dart';
import '../../../core/widgets/error_state.dart';
import 'widgets/session_card.dart';
import '../application/sessions_controller.dart';

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
  ];

  @override
  Widget build(BuildContext context) {
    final sessionsAsyncValue = ref.watch(sessionsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.9),
            radius: 1.2,
            colors: [
              Color(0x2006B6D4), // Cyan subtle glow
              Color(0x00090D14),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agent Sessions',
                          style: AppTypography.screenTitle.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Live agent loops & interactive task runs',
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/new-session'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('New Run', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Filter Pills
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = filter == _selectedFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppColors.primaryGradient : null,
                            color: isSelected ? null : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.transparent : AppColors.border,
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.accent.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            filter,
                            style: AppTypography.caption.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Sessions Content
              Expanded(
                child: sessionsAsyncValue.when(
                  data: (sessions) {
                    final filteredSessions = _selectedFilter == 'All'
                        ? sessions
                        : sessions.where((s) => s.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();

                    if (filteredSessions.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.terminal_rounded,
                                    size: 36,
                                    color: AppColors.accentLight,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Sessions Matching "$_selectedFilter"',
                                  style: AppTypography.cardTitle,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Run an agent from your workstation or launch a new loop remotely.',
                                  style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                OutlinedButton.icon(
                                  onPressed: () => context.push('/new-session'),
                                  icon: const Icon(Icons.play_arrow_rounded, color: AppColors.accentLight),
                                  label: const Text('Start New Session', style: TextStyle(color: AppColors.accentLight)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.borderHighlight),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => ref.read(sessionsControllerProvider.notifier).refresh(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredSessions.length,
                        itemBuilder: (context, index) {
                          final session = filteredSessions[index];
                          StatusType statusType = StatusType.info;
                          if (session.status == 'Failed' || session.status == 'Cancelled') statusType = StatusType.danger;
                          if (session.status == 'Waiting') statusType = StatusType.warning;
                          if (session.status == 'Completed') statusType = StatusType.success;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SessionCard(
                              title: session.title.isNotEmpty ? session.title : 'Agent Session',
                              statusType: statusType,
                              statusText: session.status,
                              duration: 'N/A',
                              workspace: session.workingDirectory,
                              branch: 'main',
                              currentActivity: session.agentType,
                              lastUpdate: 'recently',
                              onTap: () {
                                context.push('/session/${session.sessionId}');
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => ErrorState(message: error.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
