import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/security/device_manager.dart';
import '../../observe/presentation/qr_scanner_screen.dart';
import 'widgets/active_workstation_card.dart';
import 'widgets/manual_connect_dialog.dart';

class WorkspacesDashboardScreen extends StatefulWidget {
  final Function(int targetIndex)? onNavigateTab;

  const WorkspacesDashboardScreen({super.key, this.onNavigateTab});

  @override
  State<WorkspacesDashboardScreen> createState() => _WorkspacesDashboardScreenState();
}

class _WorkspacesDashboardScreenState extends State<WorkspacesDashboardScreen> {
  final DeviceManager _deviceManager = DeviceManager();
  final WebSocketClient _wsClient = WebSocketClient();

  List<SavedDevice> _savedDevices = [];
  SavedDevice? _activeDevice;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDevicesAndAutoConnect();
  }

  Future<void> _loadDevicesAndAutoConnect() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final devices = await _deviceManager.getSavedDevices();
      _savedDevices = devices;

      if (devices.isNotEmpty) {
        // Find most recently connected device, or first
        devices.sort((a, b) => (b.lastConnected ?? DateTime(2000)).compareTo(a.lastConnected ?? DateTime(2000)));
        final lastDevice = devices.first;
        _activeDevice = lastDevice;

        // Auto-reconnect if not already connected
        if (_wsClient.status == ConnectionStatus.disconnected) {
          _connectToDevice(lastDevice, isBackgroundAutoConnect: true);
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load saved devices: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _connectToDevice(SavedDevice device, {bool isBackgroundAutoConnect = false}) async {
    setState(() {
      _activeDevice = device;
      _errorMessage = null;
    });

    try {
      await _wsClient.connect(
        device.ip,
        device.port,
        null,
        (newIp, newPort) async {
          await _deviceManager.updateDeviceAddress(device.id, newIp, newPort);
          if (mounted) {
            final updated = await _deviceManager.getSavedDevices();
            setState(() => _savedDevices = updated);
          }
        },
      );
      await _deviceManager.updateDeviceAddress(device.id, device.ip, device.port);
    } catch (e) {
      if (mounted && !isBackgroundAutoConnect) {
        setState(() => _errorMessage = 'Connection failed: ${e.toString()}');
      }
    }
  }

  Future<void> _connectManual(String ip, String port, String? pairingSecret) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      await _wsClient.connect(
        ip,
        port,
        pairingSecret,
        (newIp, newPort) {},
      );

      // Create or update device in DeviceManager
      final existing = _savedDevices.firstWhere(
        (d) => d.ip == ip && d.port == port,
        orElse: () => SavedDevice(
          id: const Uuid().v4(),
          name: _wsClient.activeMachineName ?? 'Desktop Workstation',
          ip: ip,
          port: port,
          machineName: _wsClient.activeMachineName,
          lastConnected: DateTime.now(),
        ),
      );

      await _deviceManager.saveDevice(existing);
      final refreshed = await _deviceManager.getSavedDevices();

      if (mounted) {
        setState(() {
          _savedDevices = refreshed;
          _activeDevice = existing;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to desktop workstation!'),
            backgroundColor: Color(0xFF00E676),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Connection failed: ${e.toString()}');
      }
    }
  }

  void _onPairPressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF13161C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E222B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                  ),
                  title: const Text('Scan QR Code with Camera', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Mobile phone camera scans the Desktop Bridge QR', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _startCameraScan();
                  },
                ),
                const Divider(color: Color(0xFF222733)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E222B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.keyboard_alt_outlined, color: Colors.white, size: 22),
                  ),
                  title: const Text('Manual Entry / Paste URL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Enter IP address, Port, and Pairing secret', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    showDialog(
                      context: context,
                      builder: (_) => ManualConnectDialog(onConnect: _connectManual),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startCameraScan() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted || status.isLimited) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QRScannerScreen(
            onScanned: (ip, port, token) {
              Navigator.of(context).pop();
              _connectManual(ip, port, token);
            },
          ),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF13161C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF222733)),
          ),
          title: const Text('Camera Permission Required', style: TextStyle(color: Colors.white)),
          content: const Text(
            'LocalLoop requires camera access to scan pairing QR codes. Please allow camera permissions in system settings.',
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
          content: Text('Camera permission was denied. You can enter connection details manually.'),
          backgroundColor: Color(0xFF2A0D0D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0C),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.blur_on, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'LocalLoop',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Pair New Desktop',
            onPressed: _onPairPressed,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: _loadDevicesAndAutoConnect,
              color: Colors.white,
              backgroundColor: const Color(0xFF13161C),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A0D0D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFFF5252), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 1. Active Workstation Card
                  if (_activeDevice != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
                      child: Text(
                        'ACTIVE WORKSTATION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    ActiveWorkstationCard(
                      activeDevice: _activeDevice,
                      onDisconnect: () {
                        _wsClient.disconnect();
                        setState(() {});
                      },
                      onReconnect: () {
                        if (_activeDevice != null) {
                          _connectToDevice(_activeDevice!);
                        }
                      },
                      onSwitch: () {
                        // Scroll to saved workstations
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 2. Saved Workstations List or Empty State
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SAVED WORKSTATIONS (${_savedDevices.length})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.qr_code, size: 14),
                          label: const Text('Pair New', style: TextStyle(fontSize: 12)),
                          onPressed: _onPairPressed,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF90CAF9),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_savedDevices.isEmpty)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF13161C),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF222733)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E222B),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.devices, size: 40, color: Color(0xFF8A94A6)),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'No Desktop Workstation Paired',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Connect your mobile companion to a Windows host running LocalLoop Bridge.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.qr_code_scanner, size: 18),
                            label: const Text('Pair Desktop'),
                            onPressed: _onPairPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF090A0C),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._savedDevices.map((device) {
                      final isCurrentActive = _activeDevice?.id == device.id &&
                          _wsClient.status == ConnectionStatus.connected;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF13161C),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentActive ? const Color(0xFF00E676).withValues(alpha: 0.4) : const Color(0xFF222733),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E222B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.computer,
                              color: isCurrentActive ? const Color(0xFF00E676) : Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                device.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                              ),
                              if (isCurrentActive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(color: Color(0xFF00E676), fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${device.ip}:${device.port}',
                            style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12, fontFamily: 'monospace'),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5252), size: 20),
                                onPressed: () async {
                                  await _deviceManager.removeDevice(device.id);
                                  if (_activeDevice?.id == device.id) {
                                    _wsClient.disconnect();
                                    _activeDevice = null;
                                  }
                                  _loadDevicesAndAutoConnect();
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            if (_activeDevice?.id != device.id || _wsClient.status != ConnectionStatus.connected) {
                              _connectToDevice(device);
                            }
                          },
                        ),
                      );
                    }),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}
