import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/websocket_client.dart';
import '../theme/app_colors.dart';

enum TelemetryFilter {
  all,
  logs,
  diffs,
  terminal,
  errors,
}

class TelemetryLogItem {
  final String id;
  final String timestamp;
  final String tag;
  final String message;
  final Color color;
  final String rawType;
  final TelemetryFilter category;
  final Map<String, dynamic>? payload;

  const TelemetryLogItem({
    required this.id,
    required this.timestamp,
    required this.tag,
    required this.message,
    required this.color,
    required this.rawType,
    required this.category,
    this.payload,
  });
}

class TelemetryState {
  final List<TelemetryLogItem> allLogs;
  final TelemetryFilter activeFilter;
  final String searchQuery;

  const TelemetryState({
    this.allLogs = const [],
    this.activeFilter = TelemetryFilter.all,
    this.searchQuery = '',
  });

  List<TelemetryLogItem> get filteredLogs {
    return allLogs.where((log) {
      if (activeFilter != TelemetryFilter.all && log.category != activeFilter) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return log.message.toLowerCase().contains(query) ||
            log.tag.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  TelemetryState copyWith({
    List<TelemetryLogItem>? allLogs,
    TelemetryFilter? activeFilter,
    String? searchQuery,
  }) {
    return TelemetryState(
      allLogs: allLogs ?? this.allLogs,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class TelemetryNotifier extends Notifier<TelemetryState> {
  final WebSocketClient _wsClient = WebSocketClient();
  StreamSubscription<Map<String, dynamic>>? _streamSub;
  static const int _maxBufferSize = 200;

  @override
  TelemetryState build() {
    _streamSub?.cancel();
    _streamSub = _wsClient.messageStream.listen(_handleIncomingMessage);
    ref.onDispose(() {
      _streamSub?.cancel();
    });
    return const TelemetryState();
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final type = (data['type'] as String?) ?? 'event';
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    
    String tag = 'EVENT';
    Color color = AppColors.accentCyan;
    String message = '';
    TelemetryFilter category = TelemetryFilter.logs;

    final dynamic rawData = data['data'] ?? data['payload'];

    if (type.contains('log') || type == 'agent_log') {
      tag = 'LOG';
      color = AppColors.accent;
      message = rawData is String ? rawData : (rawData?['message']?.toString() ?? jsonEncode(data));
      category = TelemetryFilter.logs;
    } else if (type.contains('diff') || type == 'file_diff') {
      tag = 'DIFF';
      color = AppColors.accentCyan;
      message = rawData is Map ? (rawData['filePath'] ?? 'File modified') : 'Code diff updated';
      category = TelemetryFilter.diffs;
    } else if (type.contains('terminal') || type == 'cli_output') {
      tag = 'CLI';
      color = AppColors.textPrimary;
      message = rawData is String ? rawData : (rawData?['output']?.toString() ?? 'Command executed');
      category = TelemetryFilter.terminal;
    } else if (type.contains('error') || type == 'failure') {
      tag = 'ERR';
      color = AppColors.warning;
      message = rawData is String ? rawData : (rawData?['error']?.toString() ?? 'Error occurred');
      category = TelemetryFilter.errors;
    } else {
      tag = type.toUpperCase().replaceAll('_', ' ');
      if (tag.length > 8) tag = tag.substring(0, 8);
      message = rawData is String ? rawData : jsonEncode(rawData ?? data);
    }

    final newItem = TelemetryLogItem(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      timestamp: timeStr,
      tag: tag,
      message: message,
      color: color,
      rawType: type,
      category: category,
      payload: rawData is Map<String, dynamic> ? rawData : null,
    );

    final updated = [newItem, ...state.allLogs];
    if (updated.length > _maxBufferSize) {
      updated.removeRange(_maxBufferSize, updated.length);
    }

    state = state.copyWith(allLogs: updated);
  }

  void setFilter(TelemetryFilter filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clear() {
    state = state.copyWith(allLogs: []);
  }
}

final telemetryProvider =
    NotifierProvider<TelemetryNotifier, TelemetryState>(
  TelemetryNotifier.new,
);
