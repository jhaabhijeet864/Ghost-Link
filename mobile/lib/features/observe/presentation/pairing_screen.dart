import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'qr_scanner_screen.dart';
import '../../../core/network/websocket_client.dart';
import '../../../core/security/device_manager.dart';
import '../../../core/router/app_router.dart';
import 'package:uuid/uuid.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final DeviceManager _deviceManager = DeviceManager();
  List<SavedDevice> _savedDevices = [];
  bool _isConnecting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final devices = await _deviceManager.getSavedDevices();
    setState(() {
      _savedDevices = devices;
    });
  }

  Future<void> _connectToDevice(SavedDevice device) async {
    await _connect(device.ip, device.port, null, device);
  }

  Future<void> _connect(String ip, String port, String? pairingSecret, [SavedDevice? existingDevice]) async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      final wsClient = WebSocketClient();
      await wsClient.connect(
        ip,
        port,
        pairingSecret,
        (newIp, newPort) async {
          if (existingDevice != null) {
            await _deviceManager.updateDeviceAddress(existingDevice.id, newIp, newPort);
          }
        },
      );
      
      if (existingDevice == null) {
        final newDevice = SavedDevice(
          id: const Uuid().v4(),
          name: 'Desktop Workspace',
          ip: ip,
          port: port,
          lastConnected: DateTime.now(),
        );
        await _deviceManager.saveDevice(newDevice);
      } else {
        await _deviceManager.updateDeviceAddress(existingDevice.id, ip, port);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MainNavigationShell(
              token: pairingSecret ?? '',
              ip: ip,
              port: port,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Connection failed: ${e.toString()}';
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _startCameraScan() async {
    // Request runtime camera permission from the operating system (triggers mobile system popup)
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted || status.isLimited) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QRScannerScreen(
            onScanned: (ip, port, token) {
              Navigator.of(context).pop();
              _connect(ip, port, token);
            },
          ),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF121418),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2A2E39)),
          ),
          title: const Text('Camera Permission Required', style: TextStyle(color: Colors.white)),
          content: const Text(
            'LocalLoop requires camera access to scan pairing QR codes from your workstation. Please enable camera access in system settings.',
            style: TextStyle(color: Color(0xFF8A94A6)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF8A94A6))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission was denied. You can also enter the pairing URL manually.'),
          backgroundColor: Color(0xFF2A0D0D),
        ),
      );
    }
  }

  void _onPairPressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121418),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pair Desktop Workstation',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  title: const Text('Scan QR Code with Camera', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('For mobile phones or devices with a camera', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _startCameraScan();
                  },
                ),
                const Divider(color: Color(0xFF2A2E39)),
                ListTile(
                  leading: const Icon(Icons.paste, color: Colors.white),
                  title: const Text('Manual Entry / Paste URL', style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Paste pairing URI or connect to localhost', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showManualEntryDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManualEntryDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121418),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2A2E39)),
          ),
          title: const Text('Enter Pairing URL or Token', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'localloop://pair?token=...&ip=...&port=8080',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.content_paste, color: Colors.white70),
                    onPressed: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        textController.text = data!.text!;
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.laptop, size: 18),
                  label: const Text('Quick Connect to Localhost (8080)'),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    // Connect to localhost directly
                    _connect('127.0.0.1', '8080', null);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF8A94A6))),
            ),
            ElevatedButton(
              onPressed: () {
                final text = textController.text.trim();
                Navigator.of(ctx).pop();
                if (text.startsWith('localloop://pair')) {
                  try {
                    final uri = Uri.parse(text);
                    final ip = uri.queryParameters['ip'] ?? '127.0.0.1';
                    final port = uri.queryParameters['port'] ?? '8080';
                    final token = uri.queryParameters['token'];
                    _connect(ip, port, token);
                  } catch (e) {
                    setState(() => _error = 'Invalid URL format');
                  }
                } else if (text.isNotEmpty) {
                  // Treat as token connecting to localhost
                  _connect('127.0.0.1', '8080', text);
                }
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnecting) {
      return Scaffold(
        appBar: AppBar(title: const Text('Connecting')),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('LocalLoop Devices'),
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A0D0D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF3D00).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFF3D00), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _savedDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121418),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF2A2E39)),
                          ),
                          child: const Icon(Icons.computer, size: 56, color: Color(0xFF8A94A6)),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Desktop Paired',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Scan the QR code on your Windows workstation.',
                          style: TextStyle(color: Color(0xFF8A94A6), fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _savedDevices.length,
                    itemBuilder: (context, index) {
                      final device = _savedDevices[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121418),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2A2E39)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1D24),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF2A2E39)),
                            ),
                            child: const Icon(Icons.computer, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            device.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          subtitle: Text(
                            'IP: ${device.ip}:${device.port}',
                            style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFFF3D00)),
                            onPressed: () async {
                              await _deviceManager.removeDevice(device.id);
                              _loadDevices();
                            },
                          ),
                          onTap: () => _connectToDevice(device),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner, size: 20),
                label: const Text('Pair New Desktop', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                onPressed: _onPairPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF090A0C),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
