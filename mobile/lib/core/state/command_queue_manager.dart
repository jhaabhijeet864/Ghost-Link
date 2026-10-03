import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../data/database/app_database.dart';
import '../network/websocket_client.dart';

class QueuedCommand {
  final int? id;
  final String correlationId;
  final String action;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  QueuedCommand({
    this.id,
    required this.correlationId,
    required this.action,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'device_id': 'local',
      'intent_id': correlationId,
      'input': jsonEncode(payload),
      'action': action,
      'target': payload['target']?.toString() ?? 'host',
      'risk_level': 'low',
      'status': 'queued',
      'result': '',
      'timestamp': createdAt.toIso8601String(),
    };
  }
}

class CommandQueueManager {
  static final CommandQueueManager _instance = CommandQueueManager._internal();
  factory CommandQueueManager() => _instance;
  CommandQueueManager._internal();

  final List<QueuedCommand> _memoryQueue = [];
  final ValueNotifier<int> queueCountNotifier = ValueNotifier<int>(0);
  bool _isFlushing = false;

  int get count => _memoryQueue.length;

  Future<void> enqueue(String action, Map<String, dynamic> payload) async {
    final cmd = QueuedCommand(
      correlationId: payload['correlationId']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      action: action,
      payload: payload,
      createdAt: DateTime.now(),
    );

    _memoryQueue.add(cmd);
    queueCountNotifier.value = _memoryQueue.length;

    try {
      if (!kIsWeb) {
        final db = await AppDatabase().database;
        await db?.insert('command_history', cmd.toMap());
      }
    } catch (_) {}
  }

  Future<void> flush(WebSocketClient client) async {
    if (_isFlushing || _memoryQueue.isEmpty) return;
    if (client.status != ConnectionStatus.connected) return;

    _isFlushing = true;
    try {
      while (_memoryQueue.isNotEmpty && client.status == ConnectionStatus.connected) {
        final nextCmd = _memoryQueue.removeAt(0);
        queueCountNotifier.value = _memoryQueue.length;
        try {
          await client.sendCommand(nextCmd.payload);
        } catch (_) {
          // If sending fails, re-insert at beginning and abort flush
          _memoryQueue.insert(0, nextCmd);
          queueCountNotifier.value = _memoryQueue.length;
          break;
        }
      }
    } finally {
      _isFlushing = false;
    }
  }

  void clear() {
    _memoryQueue.clear();
    queueCountNotifier.value = 0;
  }
}
