import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_loop/core/state/telemetry_state.dart';

void main() {
  group('TelemetryState & Filtering Tests', () {
    const log1 = TelemetryLogItem(
      id: '1',
      timestamp: '10:00:00',
      tag: 'LOG',
      message: 'Agent completed indexing',
      color: Colors.green,
      rawType: 'agent_log',
      category: TelemetryFilter.logs,
    );

    const diff1 = TelemetryLogItem(
      id: '2',
      timestamp: '10:00:05',
      tag: 'DIFF',
      message: 'Modified app_router.dart',
      color: Colors.cyan,
      rawType: 'file_diff',
      category: TelemetryFilter.diffs,
    );

    const err1 = TelemetryLogItem(
      id: '3',
      timestamp: '10:00:10',
      tag: 'ERR',
      message: 'Failed to compile target',
      color: Colors.red,
      rawType: 'failure',
      category: TelemetryFilter.errors,
    );

    test('Filter returns all logs when activeFilter is all', () {
      final state = TelemetryState(allLogs: [log1, diff1, err1]);
      expect(state.filteredLogs.length, 3);
    });

    test('Filter returns only matching category', () {
      final state = TelemetryState(
        allLogs: [log1, diff1, err1],
        activeFilter: TelemetryFilter.diffs,
      );
      expect(state.filteredLogs.length, 1);
      expect(state.filteredLogs.first.id, '2');
    });

    test('Search query filters across message and tag', () {
      final state = TelemetryState(
        allLogs: [log1, diff1, err1],
        searchQuery: 'compile',
      );
      expect(state.filteredLogs.length, 1);
      expect(state.filteredLogs.first.id, '3');
    });
  });
}
