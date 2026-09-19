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
      case 'Low': return Colors.green;
      case 'Medium': return Colors.orange;
      case 'High': return Colors.red;
      default: return Colors.grey;
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
    setState(() => _isConnected = true);
    
    _wsClient.approvalStream.listen((approval) {
      final intent = approval['data'] as Map<String, dynamic>;
      final item = ApprovalItem.fromJson({
        ...intent,
        'status': 'pending',
      });
      ref.read(pendingApprovalsProvider.notifier).add(item);
    });
    
    _wsClient.messageStream.listen((message) {
      if (message['type'] == 'command_response') {
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null && data['intentId'] != null) {
          final success = data['success'] as bool? ?? false;
          ref.read(pendingApprovalsProvider.notifier).updateStatus(
            data['intentId'] as String,
            success ? 'approved' : 'rejected',
          );
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
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${pending.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(history),
            tooltip: 'Approval History',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
            width: double.infinity,
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isConnected ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Connected to Desktop' : 'Disconnected',
                  style: TextStyle(
                    color: _isConnected ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.w500,
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
                    Icon(
                      Icons.check_circle_outline,
                      size: 64,
                      color: Colors.green.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No pending approvals',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You have no actions waiting for your review.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(item.riskIcon, color: item.riskColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.action} ${item.target}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Risk: ${item.riskLevel}',
                        style: TextStyle(fontSize: 12, color: item.riskColor),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: item.riskColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    item.riskLevel,
                    style: TextStyle(
                      fontSize: 12,
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
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Text(
              'Requested: ${_formatTime(item.timestamp)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectConfirmation(item),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _respondToApproval(item, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.riskColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
        title: const Text('Reject Action'),
        content: Text('Are you sure you want to reject "${item.action} ${item.target}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _respondToApproval(item, false);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
        title: const Text('Approval History'),
        content: SizedBox(
          width: double.maxFinite,
          child: history.isEmpty
              ? const Center(child: Text('No history yet'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final isApproved = item.status == 'approved';
                    return ListTile(
                      leading: Icon(
                        isApproved ? Icons.check_circle : Icons.cancel,
                        color: isApproved ? Colors.green : Colors.red,
                      ),
                      title: Text('${item.action} ${item.target}'),
                      subtitle: Text('${item.status} • ${_formatTime(item.timestamp)}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.riskColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(item.riskLevel, style: TextStyle(fontSize: 10, color: item.riskColor)),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}