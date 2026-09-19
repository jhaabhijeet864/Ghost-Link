import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/security/crypto_manager.dart';
import '../../../../core/security/device_manager.dart';

class SettingsScreen extends StatefulWidget {
  final Function(int targetIndex)? onNavigateTab;

  const SettingsScreen({super.key, this.onNavigateTab});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CryptoManager _cryptoManager = CryptoManager();
  final DeviceManager _deviceManager = DeviceManager();
  final WebSocketClient _wsClient = WebSocketClient();

  String? _publicKeyBase64;
  String? _fingerprint;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceIdentity();
  }

  Future<void> _loadDeviceIdentity() async {
    try {
      final keyStr = await _cryptoManager.getPublicKeyBase64();
      _publicKeyBase64 = keyStr;
      
      // Generate readable fingerprint
      if (keyStr.length > 16) {
        _fingerprint = '${keyStr.substring(0, 8)}...${keyStr.substring(keyStr.length - 8)}';
      } else {
        _fingerprint = keyStr;
      }
    } catch (_) {
      _fingerprint = 'Generating keypair...';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmRevokeAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF13161C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF222733)),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 24),
            SizedBox(width: 8),
            Text('Revoke All Pairings?', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'This will remove all saved workstation pairings, disconnect active sessions, and require re-scanning the QR code to pair again.',
          style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8A94A6))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5252), foregroundColor: Colors.white),
            child: const Text('Revoke All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _wsClient.disconnect();
      final devices = await _deviceManager.getSavedDevices();
      for (final d in devices) {
        await _deviceManager.removeDevice(d.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All workstation pairings have been revoked.'),
            backgroundColor: Color(0xFF2A0D0D),
          ),
        );
        widget.onNavigateTab?.call(0); // Switch to Workspaces
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090A0C),
      appBar: AppBar(
        title: const Text('Settings & Security', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Device Identity Card
                Text(
                  'DEVICE CRYPTOGRAPHIC IDENTITY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13161C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF222733)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E222B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.fingerprint, color: Color(0xFF00E676), size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ed25519 Signing Key',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Curve25519 • Hardware/Secure Keystore',
                                  style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFF222733)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Key Fingerprint:', style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                          Row(
                            children: [
                              Text(
                                _fingerprint ?? 'Unknown',
                                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
                              ),
                              if (_publicKeyBase64 != null) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: _publicKeyBase64!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Public key copied to clipboard')),
                                    );
                                  },
                                  child: const Icon(Icons.copy, color: Color(0xFF90CAF9), size: 14),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Risk Policy Inspector
                Text(
                  'COMMAND & APPROVAL POLICIES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13161C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF222733)),
                  ),
                  child: Column(
                    children: [
                      _buildPolicyRow('Telemetry & Logs (Read)', 'Auto-allowed', const Color(0xFF00E676)),
                      const Divider(color: Color(0xFF222733), height: 18),
                      _buildPolicyRow('File Modifications', 'Requires Mobile Approval', const Color(0xFFFFB300)),
                      const Divider(color: Color(0xFF222733), height: 18),
                      _buildPolicyRow('Terminal & Shell Commands', 'Requires Mobile Approval', const Color(0xFFFFB300)),
                      const Divider(color: Color(0xFF222733), height: 18),
                      _buildPolicyRow('Replay Attack Window', '30 Seconds (Max)', Colors.white70),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Revocation & Danger Zone
                Text(
                  'PAIRINGS MANAGEMENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF13161C),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2A1C1C)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Revoke Workstation Pairings',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Disconnects from active workstation and removes all saved machine secrets from secure storage.',
                        style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_forever, size: 18),
                          label: const Text('Revoke All Pairings'),
                          onPressed: _confirmRevokeAll,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF5252),
                            side: const BorderSide(color: Color(0xFF4A1E1E)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPolicyRow(String title, String rule, Color ruleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ruleColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ruleColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            rule,
            style: TextStyle(color: ruleColor, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
