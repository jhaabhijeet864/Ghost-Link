class ActiveAgentSession {
  final String sessionId;
  final String agentType;
  final String title;
  final int processId;
  final String status;
  final String workingDirectory;
  final DateTime lastActiveTimestamp;

  const ActiveAgentSession({
    required this.sessionId,
    required this.agentType,
    required this.title,
    required this.processId,
    this.status = 'Active',
    this.workingDirectory = '',
    required this.lastActiveTimestamp,
  });

  factory ActiveAgentSession.fromJson(Map<String, dynamic> json) {
    return ActiveAgentSession(
      sessionId: json['sessionId'] as String? ?? '',
      agentType: json['agentType'] as String? ?? 'AntigravityIDE',
      title: json['title'] as String? ?? 'AI Coding Agent',
      processId: json['processId'] as int? ?? 0,
      status: json['status'] as String? ?? 'Active',
      workingDirectory: json['workingDirectory'] as String? ?? '',
      lastActiveTimestamp: json['lastActiveTimestamp'] != null
          ? DateTime.tryParse(json['lastActiveTimestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get displayName {
    if (agentType == 'AntigravityIDE') return 'Antigravity IDE';
    if (agentType == 'ClaudeCode') return 'Claude Code';
    if (agentType == 'AntigravityCli') return 'Antigravity CLI';
    if (agentType == 'OpenCode') return 'OpenCode';
    return title.isNotEmpty ? title : agentType;
  }
}
