import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/active_agent_session.dart';
import '../../core/network/websocket_client.dart';
import '../command/widgets/voice_dictation_modal.dart';

// Stream of discovered agent sessions from Desktop Bridge
final agentSessionsStreamProvider = StreamProvider.autoDispose<List<ActiveAgentSession>>((ref) {
  final ws = WebSocketClient();
  return ws.messageStream.where((msg) => msg['type'] == 'agent_sessions').map((msg) {
    try {
      final list = jsonDecode(msg['data'] as String) as List;
      return list.map((item) => ActiveAgentSession.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return <ActiveAgentSession>[];
    }
  });
});

// Currently selected target agent session
final selectedAgentSessionProvider = StateProvider<ActiveAgentSession?>((ref) => null);

// Activity items model
class AgentActivityItem {
  final String id;
  final String type; // 'user_prompt', 'agent_thought', 'tool_call', 'tool_output', 'approval_pending'
  final String title;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? rawData;

  AgentActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.timestamp,
    this.rawData,
  });
}

class ControlRoomScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenWorkspaces;
  final VoidCallback? onOpenSettings;

  const ControlRoomScreen({
    super.key,
    this.onOpenWorkspaces,
    this.onOpenSettings,
  });

  @override
  ConsumerState<ControlRoomScreen> createState() => _ControlRoomScreenState();
}

class _ControlRoomScreenState extends ConsumerState<ControlRoomScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final WebSocketClient _wsClient = WebSocketClient();

  final List<AgentActivityItem> _activities = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _isConnected = _wsClient.status == ConnectionStatus.connected;
    if (!_isConnected) {
      final host = kIsWeb && Uri.base.host.isNotEmpty ? Uri.base.host : (_wsClient.activeMachineName ?? '192.168.1.2');
      _wsClient.connect(host, '8080');
    }

    _wsClient.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _isConnected = status == ConnectionStatus.connected;
        });
      }
    });

    // Listen to real-time agent activities from transcript stream
    _wsClient.messageStream.listen((msg) {
      if (!mounted) return;
      final type = msg['type'] as String?;

      if (type == 'app_event') {
        try {
          final eventData = jsonDecode(msg['data'] as String);
          if (eventData['Type'] == 'agent_activity') {
            final payload = jsonDecode(eventData['Payload'] as String);
            _parseTranscriptPayload(payload);
          }
        } catch (_) {}
      } else if (type == 'command_response') {
        final success = msg['data']?['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Prompt delivered to desktop agent' : 'Prompt execution error'),
            duration: const Duration(seconds: 2),
            backgroundColor: success ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
          ),
        );
      }
    });

    // Listen to live approvals
    _wsClient.approvalStream.listen((approvalMsg) {
      if (!mounted) return;
      setState(() {
        _activities.add(AgentActivityItem(
          id: approvalMsg['intentId'] ?? DateTime.now().toString(),
          type: 'approval_pending',
          title: 'Action Requires Approval',
          content: approvalMsg['explanation'] ?? 'The agent wants to execute a sensitive action.',
          timestamp: DateTime.now(),
          rawData: approvalMsg,
        ));
      });
      _scrollToBottom();
    });

    // Initial mock activity if feed is empty
    if (_activities.isEmpty) {
      _activities.add(AgentActivityItem(
        id: 'init-1',
        type: 'agent_thought',
        title: 'LocalLoop Agent Bridge',
        content: 'Connected to desktop workstation. Monitoring active coding sessions...',
        timestamp: DateTime.now(),
      ));
    }
  }

  void _parseTranscriptPayload(Map<String, dynamic> payload) {
    final type = payload['type'] as String? ?? '';
    final source = payload['source'] as String? ?? '';
    final content = payload['content'] as String? ?? '';

    String itemType = 'agent_thought';
    String title = 'Agent Thought';

    if (source == 'USER_EXPLICIT' || type == 'USER_INPUT') {
      itemType = 'user_prompt';
      title = 'Developer Prompt';
    } else if (type == 'RUN_COMMAND') {
      itemType = 'tool_call';
      title = 'Terminal Command';
    } else if (payload.containsKey('tool_calls')) {
      itemType = 'tool_call';
      final tools = payload['tool_calls'] as List?;
      final firstTool = tools?.isNotEmpty == true ? tools!.first['name'] : 'tool_execution';
      title = 'Executing: $firstTool';
    }

    if (content.isNotEmpty || payload.containsKey('tool_calls')) {
      setState(() {
        _activities.add(AgentActivityItem(
          id: '${payload['step_index'] ?? DateTime.now().millisecondsSinceEpoch}',
          type: itemType,
          title: title,
          content: content.isNotEmpty ? content : jsonEncode(payload['tool_calls'] ?? {}),
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendPrompt(String promptText) async {
    if (promptText.trim().isEmpty) return;

    final selectedAgent = ref.read(selectedAgentSessionProvider);
    final target = selectedAgent?.title ?? 'Antigravity IDE';

    // Add locally to feed immediately
    setState(() {
      _activities.add(AgentActivityItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'user_prompt',
        title: 'Prompt to $target',
        content: promptText,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
    _promptController.clear();

    // Send signed prompt envelope to desktop bridge
    try {
      await _wsClient.sendCommand({
        'intentId': DateTime.now().millisecondsSinceEpoch.toString(),
        'action': 'inject_prompt',
        'target': target,
        'parameters': {
          'prompt': promptText,
          'targetWindow': target,
        },
        'riskLevel': 'Low',
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send prompt: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openAgentSelectorSheet(List<ActiveAgentSession> sessions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hub_outlined, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Detected Desktop Agents',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (sessions.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1116),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A2E39)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.terminal, color: Color(0xFF00E676), size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Antigravity IDE (Ghost-Link)\nAuto-detected via desktop bridge',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ...sessions.map((session) {
                    final isSelected = ref.watch(selectedAgentSessionProvider)?.sessionId == session.sessionId;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00E676).withOpacity(0.2) : const Color(0xFF0F1116),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          session.agentType == 'AntigravityIDE' ? Icons.code : Icons.terminal,
                          color: isSelected ? const Color(0xFF00E676) : Colors.white70,
                          size: 20,
                        ),
                      ),
                      title: Text(session.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text(session.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 20) : null,
                      onTap: () {
                        ref.read(selectedAgentSessionProvider.notifier).state = session;
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoveredSessionsAsync = ref.watch(agentSessionsStreamProvider);
    final sessions = discoveredSessionsAsync.value ?? [];
    final selectedAgent = ref.watch(selectedAgentSessionProvider);

    final activeTitle = selectedAgent?.displayName ??
        (sessions.isNotEmpty ? sessions.first.displayName : 'Antigravity IDE');

    return Scaffold(
      backgroundColor: const Color(0xFF090A0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090A0C),
        elevation: 0,
        title: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openAgentSelectorSheet(sessions),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF161922),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2E39)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  activeTitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white70),
              ],
            ),
          ),
        ),
        actions: [
          ValueListenableBuilder<int?>(
            valueListenable: _wsClient.latencyNotifier,
            builder: (context, latency, child) {
              if (latency == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    '${latency}ms',
                    style: const TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Network warning banner if disconnected
          if (!_isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF381212),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Color(0xFFFF5252), size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Disconnected. Connect to laptop Wi-Fi or Hotspot.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _wsClient.connect(
                        _wsClient.activeMachineName ?? '192.168.1.2',
                        '8080',
                      );
                    },
                    child: const Text('Retry', style: TextStyle(color: Color(0xFFFF8A80), fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Live Activity Stream
          Expanded(
            child: _activities.isEmpty
                ? const Center(
                    child: Text(
                      'Awaiting agent activity...',
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _activities.length,
                    itemBuilder: (context, index) {
                      final item = _activities[index];
                      return _buildActivityCard(item);
                    },
                  ),
          ),

          // Quick Action Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildQuickActionPill('Run Tests', () => _sendPrompt('Run the unit and integration tests')),
                const SizedBox(width: 8),
                _buildQuickActionPill('Git Status', () => _sendPrompt('Check git status and pending changes')),
                const SizedBox(width: 8),
                _buildQuickActionPill('Explain Current Step', () => _sendPrompt('Explain what you are doing right now')),
                const SizedBox(width: 8),
                _buildQuickActionPill('Stop / Cancel', () => _sendPrompt('Please stop current execution')),
              ],
            ),
          ),

          // Bottom Prompt Composer
          _buildPromptComposer(),
        ],
      ),
    );
  }

  Widget _buildActivityCard(AgentActivityItem item) {
    Color borderColor = const Color(0xFF2A2E39);
    IconData icon = Icons.psychology;
    Color iconColor = const Color(0xFF64B5F6);

    if (item.type == 'user_prompt') {
      borderColor = const Color(0xFF00E676).withOpacity(0.4);
      icon = Icons.send_rounded;
      iconColor = const Color(0xFF00E676);
    } else if (item.type == 'tool_call') {
      borderColor = const Color(0xFFFFB300).withOpacity(0.4);
      icon = Icons.terminal;
      iconColor = const Color(0xFFFFB300);
    } else if (item.type == 'approval_pending') {
      return _buildApprovalCard(item);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF121418),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                item.title,
                style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              Text(
                '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.content,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(AgentActivityItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1B10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF9100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.shield_outlined, color: Color(0xFFFF9100), size: 18),
              SizedBox(width: 8),
              Text(
                'ACTION REQUIRES APPROVAL',
                style: TextStyle(color: Color(0xFFFF9100), fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.content,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final intentId = item.rawData?['intentId'] ?? '';
                    _wsClient.sendApprovalResponse({'intentId': intentId, 'approved': false});
                    setState(() => _activities.remove(item));
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5252),
                    side: const BorderSide(color: Color(0xFFFF5252)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final intentId = item.rawData?['intentId'] ?? '';
                    _wsClient.sendApprovalResponse({'intentId': intentId, 'approved': true});
                    setState(() => _activities.remove(item));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionPill(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2E39)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildPromptComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF121418),
        border: Border(top: BorderSide(color: Color(0xFF2A2E39))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.mic, color: Color(0xFF00E676)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => VoiceDictationModal(
                  onTranscriptConfirmed: (text) {
                    _promptController.text = text;
                  },
                ),
              );
            },
          ),
          Expanded(
            child: TextField(
              controller: _promptController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Prompt active desktop agent...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF090A0C),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF2A2E39)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF2A2E39)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF00E676)),
                ),
              ),
              onSubmitted: _sendPrompt,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Color(0xFF00E676)),
            onPressed: () => _sendPrompt(_promptController.text),
          ),
        ],
      ),
    );
  }
}
