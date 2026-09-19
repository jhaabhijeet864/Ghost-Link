import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class DiffTab extends StatelessWidget {
  const DiffTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.standard),
      children: [
        // Summary
        Text('Changed Files (2)', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.small),
        
        // File Diff Card
        _buildDiffCard(
          filename: 'lib/core/network/websocket_client.dart',
          additions: 12,
          deletions: 4,
          diffLines: [
            _DiffLine('  Future<void> connect() async {', type: _DiffType.unchanged),
            _DiffLine('-    _channel = WebSocketChannel.connect(Uri.parse(url));', type: _DiffType.deletion),
            _DiffLine('+    try {', type: _DiffType.addition),
            _DiffLine('+      _channel = WebSocketChannel.connect(Uri.parse(url));', type: _DiffType.addition),
            _DiffLine('+      await _channel!.ready;', type: _DiffType.addition),
            _DiffLine('+    } catch (e) {', type: _DiffType.addition),
            _DiffLine('+      _handleError(e);', type: _DiffType.addition),
            _DiffLine('+    }', type: _DiffType.addition),
            _DiffLine('  }', type: _DiffType.unchanged),
          ],
        ),
        
        const SizedBox(height: AppSpacing.standard),
        
        _buildDiffCard(
          filename: 'pubspec.yaml',
          additions: 1,
          deletions: 1,
          diffLines: [
            _DiffLine(' dependencies:', type: _DiffType.unchanged),
            _DiffLine('-  web_socket_channel: ^2.4.0', type: _DiffType.deletion),
            _DiffLine('+  web_socket_channel: ^2.4.1', type: _DiffType.addition),
          ],
        ),
      ],
    );
  }

  Widget _buildDiffCard({
    required String filename,
    required int additions,
    required int deletions,
    required List<_DiffLine> diffLines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.standard, vertical: AppSpacing.small),
            color: AppColors.surfacePressed,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    filename,
                    style: AppTypography.code.copyWith(fontSize: 12, color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
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
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 16),
                  onPressed: () {},
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // Diff Content (Horizontal Scrollable)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: diffLines.map((line) => _buildDiffLineWidget(line)).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffLineWidget(_DiffLine line) {
    Color bgColor = Colors.transparent;
    Color textColor = AppColors.textSecondary;
    
    if (line.type == _DiffType.addition) {
      bgColor = AppColors.success.withValues(alpha: 0.1);
      textColor = AppColors.success;
    } else if (line.type == _DiffType.deletion) {
      bgColor = AppColors.danger.withValues(alpha: 0.1);
      textColor = AppColors.danger;
    }

    return Container(
      color: bgColor,
      width: 1000, // ensure full width coloring in horizontal scroll
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.standard, vertical: 2),
      child: Text(
        line.text,
        style: AppTypography.code.copyWith(
          color: textColor,
          fontSize: 13,
        ),
      ),
    );
  }
}

enum _DiffType { unchanged, addition, deletion }

class _DiffLine {
  final String text;
  final _DiffType type;
  _DiffLine(this.text, {required this.type});
}
