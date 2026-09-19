class ApprovalIntent {
  final String intentId;
  final String action;
  final String target;
  final String workingDirectory;
  final String command;
  final String reasoning;
  final String riskLevel;
  final DateTime timestamp;

  ApprovalIntent({
    required this.intentId,
    required this.action,
    required this.target,
    required this.workingDirectory,
    required this.command,
    required this.reasoning,
    required this.riskLevel,
    required this.timestamp,
  });

  factory ApprovalIntent.fromJson(Map<String, dynamic> json) {
    return ApprovalIntent(
      intentId: json['intentId'] ?? '',
      action: json['action'] ?? '',
      target: json['target'] ?? '',
      workingDirectory: json['workingDirectory'] ?? '',
      command: json['command'] ?? '',
      reasoning: json['reasoning'] ?? '',
      riskLevel: json['riskLevel'] ?? 'LOW',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}
