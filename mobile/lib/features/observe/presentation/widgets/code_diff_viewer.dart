import 'package:flutter/material.dart';

class CodeDiffViewer extends StatefulWidget {
  final String filePath;
  final String diffContent;
  final bool initialExpanded;

  const CodeDiffViewer({
    super.key,
    required this.filePath,
    required this.diffContent,
    this.initialExpanded = true,
  });

  @override
  State<CodeDiffViewer> createState() => _CodeDiffViewerState();
}

class _CodeDiffViewerState extends State<CodeDiffViewer> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.diffContent.split('\n');
    int addedCount = 0;
    int deletedCount = 0;

    for (final line in lines) {
      if (line.startsWith('+') && !line.startsWith('+++')) {
        addedCount++;
      } else if (line.startsWith('-') && !line.startsWith('---')) {
        deletedCount++;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121418),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF8A94A6), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.filePath.isEmpty ? 'File Diff' : widget.filePath,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (addedCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2117),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                      ),
                      child: Text(
                        '+$addedCount',
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (deletedCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A0D0D),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFF3D00).withOpacity(0.3)),
                      ),
                      child: Text(
                        '-$deletedCount',
                        style: const TextStyle(
                          color: Color(0xFFFF3D00),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF8A94A6),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0xFF2A2E39)),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              child: Container(
                color: const Color(0xFF090A0C),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(lines.length, (index) {
                      final line = lines[index];
                      return _buildDiffLine(line, index + 1);
                    }),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiffLine(String line, int lineNumber) {
    Color bg = Colors.transparent;
    Color fg = const Color(0xFFC3C7D0);
    String prefix = ' ';

    if (line.startsWith('+') && !line.startsWith('+++')) {
      bg = const Color(0xFF0D2117);
      fg = const Color(0xFF00E676);
      prefix = '+';
    } else if (line.startsWith('-') && !line.startsWith('---')) {
      bg = const Color(0xFF2A0D0D);
      fg = const Color(0xFFFF3D00);
      prefix = '-';
    } else if (line.startsWith('@@')) {
      bg = const Color(0xFF121418);
      fg = const Color(0xFF8A94A6);
      prefix = '@';
    } else if (line.startsWith('+++') || line.startsWith('---')) {
      return const SizedBox.shrink();
    }

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$lineNumber',
              style: const TextStyle(
                color: Color(0xFF8A94A6),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 16,
            child: Text(
              prefix,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            line.length > 1 && (line.startsWith('+') || line.startsWith('-'))
                ? line.substring(1)
                : line,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
