import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/status_icon.dart';

class TerminalTab extends StatelessWidget {
  const TerminalTab({super.key});

  @override
  Widget build(BuildContext context) {
    const String mockOutput = '''
> flutter test
00:00 +0: loading E:/Ghost-Link/mobile/test/phase1_widget_test.dart
00:02 +1: loading E:/Ghost-Link/mobile/test/phase2_widget_test.dart
00:05 +15: All tests passed!

Running integration tests...
Connecting to LocalLoop daemon... OK
Verifying Ed25519 signature... OK
Testing WebSocket message throughput... 
  - 100 frames: 4ms
  - 1000 frames: 32ms
  - 10000 frames: 290ms

SUCCESS: Integration tests completed in 14.2s.
''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(AppSpacing.standard),
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '> flutter test',
                      style: AppTypography.code.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                  const StatusBadge(label: 'Running', type: StatusType.info),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'CWD: /ghost-link/mobile',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
        // Output Area
        Expanded(
          child: Container(
            color: AppColors.background,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.standard),
              children: [
                Text(
                  mockOutput,
                  style: AppTypography.code,
                ),
              ],
            ),
          ),
        ),
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.standard, vertical: AppSpacing.small),
          decoration: const BoxDecoration(
            color: AppColors.surfaceElevated,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {},
                tooltip: 'Copy Output',
              ),
              IconButton(
                icon: const Icon(Icons.vertical_align_bottom, size: 20),
                onPressed: () {},
                tooltip: 'Jump to End',
              ),
              IconButton(
                icon: const Icon(Icons.pause, size: 20),
                onPressed: () {},
                tooltip: 'Pause Scrolling',
              ),
            ],
          ),
        )
      ],
    );
  }
}
