import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../approval_inbox_screen.dart';

class ApprovalDetailSheet extends StatefulWidget {
  final ApprovalItem item;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onExpired;

  const ApprovalDetailSheet({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
    required this.onExpired,
  });

  @override
  State<ApprovalDetailSheet> createState() => _ApprovalDetailSheetState();
}

class _ApprovalDetailSheetState extends State<ApprovalDetailSheet> {
  Timer? _countdownTimer;
  late int _remainingSeconds;
  static const int _totalTimeoutSeconds = 120; // 2 minutes

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startCountdown();
  }

  void _calculateRemainingTime() {
    final now = DateTime.now();
    final elapsed = now.difference(widget.item.timestamp).inSeconds;
    _remainingSeconds = (_totalTimeoutSeconds - elapsed).clamp(0, _totalTimeoutSeconds);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (_remainingSeconds <= 0) {
      widget.onExpired();
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          widget.onExpired();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isExpired = _remainingSeconds <= 0 || item.status == 'expired';
    final progress = _remainingSeconds / _totalTimeoutSeconds;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF13161C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E3440),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Risk Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.riskColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.riskIcon, color: item.riskColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.action,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Risk Level: ${item.riskLevel}',
                                style: TextStyle(
                                  color: item.riskColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Countdown badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isExpired
                          ? const Color(0xFF2A0D0D)
                          : (progress < 0.25
                              ? const Color(0xFFFF3D00).withValues(alpha: 0.15)
                              : const Color(0xFF1E222B)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isExpired
                            ? const Color(0xFFFF5252)
                            : (progress < 0.25 ? const Color(0xFFFF3D00) : const Color(0xFF2A2E39)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: isExpired
                              ? const Color(0xFFFF5252)
                              : (progress < 0.25 ? const Color(0xFFFF3D00) : const Color(0xFF8A94A6)),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isExpired ? 'EXPIRED' : _formatTimer(_remainingSeconds),
                          style: TextStyle(
                            color: isExpired
                                ? const Color(0xFFFF8A80)
                                : (progress < 0.25 ? const Color(0xFFFF8A80) : Colors.white),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Policy Explanation Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2E39)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Color(0xFF90CAF9), size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Policy Reason',
                          style: TextStyle(color: Color(0xFF90CAF9), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.explanation,
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Target Resource Section
              Text(
                'AFFECTED RESOURCE / COMMAND',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF090A0C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF222733)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.target,
                        style: const TextStyle(
                          color: Color(0xFFA7F3D0),
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Color(0xFF8A94A6), size: 16),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: item.target));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied target to clipboard')),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Cryptographic Badge
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Color(0xFF00E676)),
                  SizedBox(width: 6),
                  Text(
                    'Approval will be signed with local Ed25519 key',
                    style: TextStyle(color: Color(0xFF8A94A6), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Actions Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onReject();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF5252),
                        side: const BorderSide(color: Color(0xFF4A1E1E)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Sign & Approve'),
                      onPressed: isExpired
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              widget.onApprove();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: const Color(0xFF090A0C),
                        disabledBackgroundColor: const Color(0xFF1E222B),
                        disabledForegroundColor: const Color(0xFF8A94A6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
