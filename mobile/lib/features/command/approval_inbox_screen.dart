import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_loop/core/network/websocket_client.dart';
import 'package:local_loop/data/database/app_database.dart';

class ApprovalItem {
  final String id;
  final String action;
  final String target;
  final String riskLevel;
  final String explanation;
  final DateTime timestamp;
  final String status;

  const ApprovalItem({
    required this.id,
    required this.action,
    required this.target,
    required this.riskLevel,
    required this.explanation,
    required this.timestamp,
    required this.status,
  });

  factory ApprovalItem.fromJson(Map<String, dynamic> json) {
    return ApprovalItem(
      id: json['intentId'] as String,
      action: json['action'] as String,
      target: json['target'] as String,
      riskLevel: json['riskLevel'] as String,
      explanation: json['explanation'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }

  Color get riskColor {
    switch (riskLevel) {
      case 'Low': return const Color(0xFF00E676);
      case 'Medium': return const Color(0xFFFFB300);
      case 'High': return const Color(0xFFFF3D00);
      default: return const Color(0xFF8A94A6);
    }
  }

  IconData get riskIcon {
    switch (riskLevel) {
      case 'Low': return Icons.check_circle;
      case 'Medium': return Icons.warning;
      case 'High': return Icons.dangerous;
      default: return Icons.help;
    }
  }
}

final pendingApprovalsProvider = StateNotifierProvider<PendingApprovalsNotifier, List<ApprovalItem>>((ref) {
  return PendingApprovalsNotifier();
});

class PendingApprovalsNotifier extends StateNotifier<List<ApprovalItem>> {
  PendingApprovalsNotifier() : super([]);

  void add(ApprovalItem item) {
    state = [...state, item];
  }

  void remove(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void updateStatus(String id, String status) {
    state = state.map((item) => item.id == id ? ApprovalItem(
      id: item.id,
      action: item.action,
      target: item.target,
      riskLevel: item.riskLevel,
      explanation: item.explanation,
      timestamp: item.timestamp,
      status: status,
    ) : item).toList();
  }
}

class ApprovalInboxScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final String ip;
  final String port;
  final String token;

  const ApprovalInboxScreen({
    super.key,
    required this.deviceId,
    required this.ip,
    required this.port,
    required this.token,
  });

  @override
  ConsumerState<ApprovalInboxScreen> createState() => _ApprovalInboxScreenState();
}

class _ApprovalInboxScreenState extends ConsumerState<ApprovalInboxScreen> {
  final WebSocketClient _wsClient = WebSocketClient();
  final AppDatabase _db = AppDatabase();
  
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    await _wsClient.connect(widget.ip, widget.port, widget.token);
    if (mounted) setState(() => _isConnected = true);
    
    _wsClient.approvalStream.listen((approval) {
      final intent = approval['data'] as Map<String, dynamic>;
      final item = ApprovalItem.fromJson({
        ...intent,
        'status': 'pending',
      });
      if (mounted) ref.read(pendingApprovalsProvider.notifier).add(item);
    });
    
    _wsClient.messageStream.listen((message) {
      if (message['type'] == 'command_response') {
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null && data['intentId'] != null) {
          final success = data['success'] as bool? ?? false;
          if (mounted) {
            ref.read(pendingApprovalsProvider.notifier).updateStatus(
              data['intentId'] as String,
              success ? 'approved' : 'rejected',
            );
          }
        }
      }
    });
  }

  Future<void> _respondToApproval(ApprovalItem item, bool approved) async {
    ref.read(pendingApprovalsProvider.notifier).updateStatus(item.id, 'responding');
    
    final response = {
      'type': 'approval_response',
      'data': {
        'intentId': item.id,
        'deviceId': widget.deviceId,
        'action': item.action,
        'target': item.target,
        'riskLevel': item.riskLevel,
        'approved': approved,
      },
    };
    
    await _wsClient.sendApprovalResponse(response);
  }

  @override
  void dispose() {
    _wsClient.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingApprovals = ref.watch(pendingApprovalsProvider);
    final pending = pendingApprovals.where((a) => a.status == 'pending').toList();
    final history = pendingApprovals.where((a) => a.status != 'pending').toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Approval Inbox'),
            if (pending.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3D00),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pending.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () => _showHistoryDialog(history),
            tooltip: 'Approval History',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: _isConnected ? const Color(0xFF0D2117) : const Color(0xFF2A0D0D),
            width: double.infinity,
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isConnected ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Connected to Workstation' : 'Disconnected',
                  style: TextStyle(
                    color: _isConnected ? const Color(0xFFA7F3D0) : const Color(0xFFFF8A80),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (pending.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121418),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF2A2E39)),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        size: 56,
                        color: Color(0xFF00E676),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Pending Approvals',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You have no actions waiting for your review.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF8A94A6), fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pending.length,
                itemBuilder: (context, index) {
                  final item = pending[index];
                  return _buildApprovalCard(item);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(ApprovalItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121418),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2E39)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.riskIcon, color: item.riskColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.action} ${item.target}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Risk: ${item.riskLevel}',
                      style: TextStyle(fontSize: 12, color: item.riskColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.riskColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: item.riskColor.withOpacity(0.4)),
                ),
                child: Text(
                  item.riskLevel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item.riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.explanation,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8A94A6)),
          ),
          const SizedBox(height: 12),
          Text(
            'Requested: ${_formatTime(item.timestamp)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A94A6)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectConfirmation(item),
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFFFF3D00)),
                  label: const Text('Reject', style: TextStyle(color: Color(0xFFFF3D00), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF3D00)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _respondToApproval(item, true),
                  icon: const Icon(Icons.check, size: 18, color: Color(0xFF090A0C)),
                  label: const Text('Approve', style: TextStyle(color: Color(0xFF090A0C), fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showRejectConfirmation(ApprovalItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121418),
        title: const Text('Reject Action', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to reject "${item.action} ${item.target}"?',
          style: const TextStyle(color: Color(0xFF8A94A6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _respondToApproval(item, false);
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF3D00)),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showHistoryDialog(List<ApprovalItem> history) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121418),
        title: const Text('Approval History', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          child: history.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No history yet', style: TextStyle(color: Color(0xFF8A94A6)))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final isApproved = item.status == 'approved';
                    return ListTile(
                      leading: Icon(
                        isApproved ? Icons.check_circle : Icons.cancel,
                        color: isApproved ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
                      ),
                      title: Text('${item.action} ${item.target}', style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${item.status} • ${_formatTime(item.timestamp)}', style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 12)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: item.riskColor.withOpacity(0.3)),
                        ),
                        child: Text(item.riskLevel, style: TextStyle(fontSize: 10, color: item.riskColor, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}