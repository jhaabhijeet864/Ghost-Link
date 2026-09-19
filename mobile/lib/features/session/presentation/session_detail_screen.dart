import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_scaffold.dart';

class SessionDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final String title;

  const SessionDetailScreen({
    super.key,
    required this.sessionId,
    required this.title,
  });

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: AppTypography.screenTitle.copyWith(fontSize: 18)),
            Text(
              'Running · 8m 42s',
              style: AppTypography.caption.copyWith(color: AppColors.info),
            ),
            Text(
              'CRM API · feature/timeouts',
              style: AppTypography.caption,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pause, color: AppColors.warning),
            onPressed: () {},
            tooltip: 'Pause',
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: AppColors.danger),
            onPressed: () {},
            tooltip: 'Cancel',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              // Summary Strip
              Container(
                color: AppColors.surfaceElevated,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.standard,
                    vertical: AppSpacing.small),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current activity: Running integration tests',
                              style: AppTypography.caption),
                          Text(
                              'Changed: 7 files | Tests: 47 passed · 2 failed | Approvals: 0 pending',
                              style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.accent,
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.textMuted,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Plan'),
                  Tab(text: 'Activity'),
                  Tab(text: 'Files'),
                  Tab(text: 'Tests'),
                  Tab(text: 'Diff'),
                  Tab(text: 'Terminal'),
                  Tab(text: 'Timeline'),
                  Tab(text: 'Evidence'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          const Center(child: Text('Plan Tab (Batch 3)')),
          _buildActivityTab(),
          const Center(child: Text('Files Tab (Batch 3)')),
          const Center(child: Text('Tests Tab (Batch 3)')),
          const Center(child: Text('Diff Tab (Batch 3)')),
          const Center(child: Text('Terminal Tab (Batch 3)')),
          const Center(child: Text('Timeline Tab (Batch 3)')),
          const Center(child: Text('Evidence Tab (Batch 3)')),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.standard),
      children: [
        Text('Latest agent message', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.small),
        Container(
          padding: const EdgeInsets.all(AppSpacing.standard),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'I have modified the timeout limits on the HTTP client but two integration tests are failing because they expect the old timeout limit. I will now run the tests again.',
            style: AppTypography.body,
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        Text('Suggested next actions', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.small),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Ask agent to fix failing tests'),
        ),
        const SizedBox(height: AppSpacing.small),
        OutlinedButton(
          onPressed: () {},
          child: const Text('Review current diff'),
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.standard),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.small),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '01:24:${10 + index}',
                style: AppTypography.code.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(width: AppSpacing.standard),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.terminal,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.micro),
                        Text('[agent]', style: AppTypography.caption),
                      ],
                    ),
                    Text(
                      'Updated client.ts',
                      style: AppTypography.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
