import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_loop/core/state/connection_state.dart';

void main() {
  group('ConnectionStateModel Tests', () {
    test('Initial state defaults to disconnected with no latency', () {
      final state = ConnectionStateModel(lastUpdated: DateTime.now());
      expect(state.status, LinkStatus.disconnected);
      expect(state.isOffline, isTrue);
      expect(state.isLive, isFalse);
      expect(state.latencyMs, isNull);
    });

    test('copyWith properly updates status and latency', () {
      final state = ConnectionStateModel(lastUpdated: DateTime.now());
      final updated = state.copyWith(
        status: LinkStatus.connected,
        latencyMs: 14,
        activeHostName: 'PREDATOR-LocalLoop',
      );

      expect(updated.status, LinkStatus.connected);
      expect(updated.isLive, isTrue);
      expect(updated.isOffline, isFalse);
      expect(updated.latencyMs, 14);
      expect(updated.activeHostName, 'PREDATOR-LocalLoop');
    });

    test('clearLatency resets latency to null', () {
      final state = ConnectionStateModel(
        status: LinkStatus.connected,
        latencyMs: 25,
        lastUpdated: DateTime.now(),
      );
      final disconnected = state.copyWith(
        status: LinkStatus.disconnected,
        clearLatency: true,
      );

      expect(disconnected.status, LinkStatus.disconnected);
      expect(disconnected.latencyMs, isNull);
    });
  });
}
