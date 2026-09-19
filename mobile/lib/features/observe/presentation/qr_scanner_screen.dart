import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class QRScannerScreen extends StatefulWidget {
  final Function(String, String, String) onScanned;

  const QRScannerScreen({super.key, required this.onScanned});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final uriString = barcode.rawValue!;
        if (uriString.startsWith('localloop://pair')) {
          try {
            final uri = Uri.parse(uriString);
            final ip = uri.queryParameters['ip'];
            final port = uri.queryParameters['port'];
            final token = uri.queryParameters['token'];

            if (ip != null && port != null && token != null) {
              controller.stop();
              widget.onScanned(ip, port, token);
              break;
            }
          } catch (e) {
            // Ignore parse errors, let user scan again
          }
        }
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        controller: controller,
        onDetect: _onDetect,
        errorBuilder: (context, error) {
          final isPermissionDenied = error.errorCode == MobileScannerErrorCode.permissionDenied;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.no_photography, size: 56, color: Color(0xFFFF3D00)),
                  const SizedBox(height: 16),
                  Text(
                    isPermissionDenied
                        ? 'Camera Permission Required'
                        : 'Camera Error (${error.errorCode.name})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPermissionDenied
                        ? 'LocalLoop requires camera access to scan pairing QR codes. Please enable camera access in system settings.'
                        : (error.errorDetails?.message ?? 'Could not initialize camera hardware.'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  if (isPermissionDenied)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.settings, size: 18),
                      label: const Text('Open App Settings'),
                      onPressed: () => openAppSettings(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

