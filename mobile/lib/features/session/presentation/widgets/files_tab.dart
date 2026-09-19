import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class FilesTab extends StatelessWidget {
  const FilesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.standard),
      children: [
        _buildGroupHeader('Modified'),
        _buildFileRow(
          filename: 'websocket_client.dart',
          path: 'lib/core/network',
          additions: 12,
          deletions: 4,
          lastEvent: '12m ago',
        ),
        _buildFileRow(
          filename: 'pubspec.yaml',
          path: '.',
          additions: 1,
          deletions: 1,
          lastEvent: '14m ago',
        ),
        const SizedBox(height: AppSpacing.large),
        
        _buildGroupHeader('Added'),
        _buildFileRow(
          filename: 'auth_interceptor.dart',
          path: 'lib/core/network',
          additions: 45,
          deletions: 0,
          lastEvent: '2m ago',
        ),
      ],
    );
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.small),
      child: Text(title, style: AppTypography.sectionTitle),
    );
  }

  Widget _buildFileRow({
    required String filename,
    required String path,
    required int additions,
    required int deletions,
    required String lastEvent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.standard),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(filename, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
              ),
              Text(
                '+$additions',
                style: AppTypography.code.copyWith(fontSize: 12, color: AppColors.success),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                '-$deletions',
                style: AppTypography.code.copyWith(fontSize: 12, color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(path, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last event: $lastEvent', style: AppTypography.caption),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.code, size: 18, color: AppColors.info),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tooltip: 'Open diff',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.neutral),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tooltip: 'Ask agent',
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: AppColors.neutral),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tooltip: 'Copy path',
                  ),
                  IconButton(
                    icon: const Icon(Icons.visibility_off_outlined, size: 18, color: AppColors.warning),
                    onPressed: () {},
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tooltip: 'Exclude from context',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
