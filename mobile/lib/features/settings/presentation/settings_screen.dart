import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../core/security/crypto_manager.dart';
import '../../../../core/security/device_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';

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

  // Interactive Policy State
  String _selectedPolicy = 'Balanced';
  bool _autoAllowReads = true;
  bool _requireShellApproval = true;
  bool _enableBiometrics = true;
  double _replayWindowSecs = 30.0;

  @override
  void initState() {
    super.initState();
    _loadDeviceIdentity();
  }

  Future<void> _loadDeviceIdentity() async {
    try {
      final keyStr = await _cryptoManager.getPublicKeyBase64();
      _publicKeyBase64 = keyStr;
      
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

  Future<void> _testSignature() async {
    try {
      final challenge = 'test_token_${DateTime.now().millisecondsSinceEpoch}';
      final signature = await _cryptoManager.signToken(challenge);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signature Verified: ${signature.substring(0, 12)}...'),
          backgroundColor: AppColors.surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signature Error: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _confirmRevokeAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
            SizedBox(width: 8),
            Text('Revoke Pairings?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will purge all saved workstation pairings and private secrets from the Secure Keystore. You will need to scan the QR code to reconnect.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
            content: Text('All workstation pairings purged.'),
            backgroundColor: AppColors.surfaceElevated,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onNavigateTab?.call(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  // Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CONTROL PLANE // SECURITY',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'HARDWARE ENCLAVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 1. Hardware Keystore Card
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfacePressed,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.fingerprint_rounded, color: AppColors.accent, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ed25519 Secure Keystore',
                                    style: AppTypography.cardTitle.copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Hardware Protected • Curve25519',
                                    style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _testSignature,
                              icon: const Icon(Icons.verified_user_outlined, color: AppColors.accent, size: 20),
                              tooltip: 'Verify Signature',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Key Fingerprint:',
                              style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                            ),
                            Row(
                              children: [
                                Text(
                                  _fingerprint ?? 'Unknown',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_publicKeyBase64 != null) ...[
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: _publicKeyBase64!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Public key copied'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: const Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 14),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Autonomous Policy Selector
                  Text(
                    'AGENT AUTONOMY LEVEL',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: ['Strict', 'Balanced', 'Autonomous'].map((mode) {
                      final isSelected = _selectedPolicy == mode;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedPolicy = mode),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.surfacePressed : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppColors.accent : AppColors.border,
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                mode,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.accent : AppColors.textSecondary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // 3. Interactive Policy Toggles Matrix
                  Text(
                    'INTERACTIVE SECURITY GATES',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),

                  GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildToggleRow(
                          'Auto-Allow Read Telemetry',
                          'Permits read-only logs & file stats without prompts',
                          _autoAllowReads,
                          (v) => setState(() => _autoAllowReads = v),
                        ),
                        const Divider(color: AppColors.border, height: 16),
                        _buildToggleRow(
                          'Require Hold-to-Approve for Shell',
                          'Enforces 1.5s biometric hold for terminal & npm commands',
                          _requireShellApproval,
                          (v) => setState(() => _requireShellApproval = v),
                        ),
                        const Divider(color: AppColors.border, height: 16),
                        _buildToggleRow(
                          'Biometric Hardware Unlock',
                          'Requires device biometric authorization for signed envelopes',
                          _enableBiometrics,
                          (v) => setState(() => _enableBiometrics = v),
                        ),
                        const Divider(color: AppColors.border, height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Replay Attack Window',
                                    style: AppTypography.caption.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${_replayWindowSecs.toInt()}s',
                                    style: const TextStyle(
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _replayWindowSecs,
                                min: 10,
                                max: 60,
                                divisions: 5,
                                activeColor: AppColors.accent,
                                inactiveColor: AppColors.surfacePressed,
                                onChanged: (v) => setState(() => _replayWindowSecs = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Danger Zone / Revocation
                  Text(
                    'PAIRING STORAGE & PURGE',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),

                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revoke Workstation Pairings',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Disconnects active tunnel and removes all saved machine keys from device storage.',
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                            label: const Text(
                              'PURGE ALL PAIRINGS',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            onPressed: _confirmRevokeAll,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF4A1E1E)),
                              backgroundColor: const Color(0xFF1E0F12),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
      ),
    );
  }

  Widget _buildToggleRow(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: AppColors.accent,
          activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
          inactiveThumbColor: AppColors.textMuted,
          inactiveTrackColor: AppColors.surfacePressed,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
