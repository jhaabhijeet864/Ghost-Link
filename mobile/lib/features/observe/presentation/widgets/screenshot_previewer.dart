import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class ScreenshotPreviewer extends StatelessWidget {
  final String? lastScreenshotBase64;
  final VoidCallback onRequestScreenshot;
  final bool isRequesting;

  const ScreenshotPreviewer({
    super.key,
    required this.lastScreenshotBase64,
    required this.onRequestScreenshot,
    this.isRequesting = false,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;
    if (lastScreenshotBase64 != null && lastScreenshotBase64!.isNotEmpty) {
      try {
        imageBytes = base64Decode(lastScreenshotBase64!);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF121418),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.monitor, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Host Display Capture',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: isRequesting ? null : onRequestScreenshot,
                    icon: isRequesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF090A0C)),
                          )
                        : const Icon(Icons.camera_alt, size: 14),
                    label: Text(
                      isRequesting ? 'Capturing...' : 'Capture Fresh',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF090A0C),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF2A2E39)),
          GestureDetector(
            onTap: imageBytes != null
                ? () => _showFullScreenImage(context, imageBytes!)
                : null,
            child: Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFF090A0C),
              child: imageBytes != null
                  ? Stack(
                      children: [
                        Center(
                          child: Image.memory(
                            imageBytes,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF2A2E39)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to Zoom',
                                  style: TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.desktop_windows_outlined, size: 40, color: Color(0xFF8A94A6)),
                          SizedBox(height: 8),
                          Text(
                            'No Screenshot Captured Yet',
                            style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap "Capture Fresh" to view live host desktop.',
                            style: TextStyle(color: Color(0xFF8A94A6), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close Modal',
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Pinch to Zoom • Drag to Pan',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
