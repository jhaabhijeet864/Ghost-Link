import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/websocket_client.dart';
import '../../data/database/app_database.dart';

final quickActionsProvider = Provider<List<QuickAction>>((ref) => [
  QuickAction(
    label: 'Read Logs',
    icon: Icons.article,
    command: 'Read the latest application logs',
    riskLevel: 'Low',
  ),
  QuickAction(
    label: 'Check Status',
    icon: Icons.monitor_heart,
    command: 'Check the status of all running services',
    riskLevel: 'Low',
  ),
  QuickAction(
    label: 'Restart Service',
    icon: Icons.restart_alt,
    command: 'Restart the main application service',
    riskLevel: 'Medium',
  ),
  QuickAction(
    label: 'View Processes',
    icon: Icons.memory,
    command: 'List all running processes',
    riskLevel: 'Low',
  ),
  QuickAction(
    label: 'Kill Process',
    icon: Icons.stop_circle,
    command: 'Stop a specific process by name',
    riskLevel: 'High',
  ),
  QuickAction(
    label: 'Run Build',
    icon: Icons.build,
    command: 'Execute the build pipeline',
    riskLevel: 'Medium',
  ),
]);

class QuickAction {
  final String label;
  final IconData icon;
  final String command;
  final String riskLevel;

  const QuickAction({
    required this.label,
    required this.icon,
    required this.command,
    required this.riskLevel,
  });

  Color get riskColor {
    switch (riskLevel) {
      case 'Low':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'High':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class CommandComposerScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final String ip;
  final String port;
  final String token;

  const CommandComposerScreen({
    super.key,
    required this.deviceId,
    required this.ip,
    required this.port,
    required this.token,
  });

  @override
  ConsumerState<CommandComposerScreen> createState() => _CommandComposerScreenState();
}

class _CommandComposerScreenState extends ConsumerState<CommandComposerScreen> {
  final TextEditingController _controller = TextEditingController();
  final WebSocketClient _wsClient = WebSocketClient();
  final AppDatabase _db = AppDatabase();
  
  bool _isConnected = false;
  bool _isSending = false;
  String? _pendingIntentId;
  List<Map<String, dynamic>> _commandHistory = [];

  @override
  void initState() {
    super.initState();
    _connect();
    _loadHistory();
  }

  Future<void> _connect() async {
    await _wsClient.connect(widget.ip, widget.port, widget.token);
    setState(() => _isConnected = true);
    
    _wsClient.approvalStream.listen((approval) {
      _showApprovalDialog(approval);
    });
  }

  Future<void> _loadHistory() async {
    final history = await _db.getCommandHistory(widget.deviceId);
    setState(() => _commandHistory = history);
  }

  Future<void> _sendCommand(String input) async {
    if (input.trim().isEmpty) return;
    
    setState(() => _isSending = true);
    
    final command = {
      'type': 'command_request',
      'data': {
        'intentId': DateTime.now().millisecondsSinceEpoch.toString(),
        'deviceId': widget.deviceId,
        'action': 'execute',
        'target': 'command',
        'parameters': {'input': input},
        'riskLevel': 'Medium',
        'explanation': 'User command: $input',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Pending',
      },
      'correlationId': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    
    await _wsClient.sendCommand(command);
    _controller.clear();
    setState(() => _isSending = false);
  }

  void _showApprovalDialog(Map<String, dynamic> approval) {
    final intent = approval['data'] as Map<String, dynamic>;
    final intentId = intent['intentId'] as String;
    
    setState(() => _pendingIntentId = intentId);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getRiskIcon(intent['riskLevel'] as String? ?? 'Medium'),
              color: _getRiskColor(intent['riskLevel'] as String? ?? 'Medium'),
            ),
            const SizedBox(width: 8),
            const Text('Approval Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Action: ${intent['action']}'),
            Text('Target: ${intent['target']}'),
            Text('Risk Level: ${intent['riskLevel']}'),
            const SizedBox(height: 8),
            Text('Explanation: ${intent['explanation']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _respondToApproval(intentId, false);
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _respondToApproval(intentId, true);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToApproval(String intentId, bool approved) async {
    final response = {
      'type': 'approval_response',
      'data': {
        'intentId': intentId,
        'deviceId': widget.deviceId,
        'action': 'unknown',
        'target': 'unknown',
        'riskLevel': 'Medium',
        'approved': approved,
      },
    };
    await _wsClient.sendApprovalResponse(response);
    setState(() => _pendingIntentId = null);
  }

  IconData _getRiskIcon(String riskLevel) {
    switch (riskLevel) {
      case 'Low': return Icons.check_circle;
      case 'Medium': return Icons.warning;
      case 'High': return Icons.dangerous;
      default: return Icons.help;
    }
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Low': return Colors.green;
      case 'Medium': return Colors.orange;
      case 'High': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  void dispose() {
    _wsClient.disconnect();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Command Composer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(),
            tooltip: 'Command History',
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickActionsProvider(ref).map((action) => 
                      ActionChip(
                        avatar: Icon(action.icon, size: 18),
                        label: Text(action.label),
                        backgroundColor: action.riskColor.withOpacity(0.1),
                        onPressed: () => _sendCommand(action.command),
                        side: BorderSide(color: action.riskColor.withOpacity(0.3)),
                      )
                    ).toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Custom Command',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a command (e.g., "Restart the web server")...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.mic),
                      suffixIcon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () => _sendCommand(_controller.text),
                            ),
                    ),
                    maxLines: 3,
                    onSubmitted: _sendCommand,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Risk Level Guide',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRiskChip('Low', Colors.green, 'Auto-approved'),
                      const SizedBox(width: 8),
                      _buildRiskChip('Medium', Colors.orange, 'Asks for approval'),
                      const SizedBox(width: 8),
                      _buildRiskChip('High', Colors.red, 'Requires explicit approval'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskChip(String label, Color color, String description) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(description, style: TextStyle(fontSize: 12, color: color.shade800)),
          ],
        ),
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Command History'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _commandHistory.length,
            itemBuilder: (context, index) {
              final cmd = _commandHistory[index];
              return ListTile(
                title: Text(cmd['input'] ?? 'Unknown'),
                subtitle: Text('${cmd['status']} • ${cmd['timestamp']}'),
                leading: Icon(
                  cmd['status'] == 'success' ? Icons.check_circle : Icons.error,
                  color: cmd['status'] == 'success' ? Colors.green : Colors.red,
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