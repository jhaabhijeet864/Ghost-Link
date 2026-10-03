import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/websocket_client.dart';

enum LinkStatus {
  connected,
  reconnecting,
  disconnected,
  authenticating,
}

class ConnectionStateModel {
  final LinkStatus status;
  final int? latencyMs;
  final String? activeHostName;
  final String? hostIp;
  final String? hostPort;
  final int reconnectAttempts;
  final int offlineQueueCount;
  final String? lastError;
  final DateTime lastUpdated;

  const ConnectionStateModel({
    this.status = LinkStatus.disconnected,
    this.latencyMs,
    this.activeHostName,
    this.hostIp,
    this.hostPort,
    this.reconnectAttempts = 0,
    this.offlineQueueCount = 0,
    this.lastError,
    required this.lastUpdated,
  });

  bool get isLive => status == LinkStatus.connected;
  bool get isReconnecting => status == LinkStatus.reconnecting;
  bool get isAuthenticating => status == LinkStatus.authenticating;
  bool get isOffline => status == LinkStatus.disconnected;

  ConnectionStateModel copyWith({
    LinkStatus? status,
    int? latencyMs,
    bool clearLatency = false,
    String? activeHostName,
    String? hostIp,
    String? hostPort,
    int? reconnectAttempts,
    int? offlineQueueCount,
    String? lastError,
    bool clearError = false,
    DateTime? lastUpdated,
  }) {
    return ConnectionStateModel(
      status: status ?? this.status,
      latencyMs: clearLatency ? null : (latencyMs ?? this.latencyMs),
      activeHostName: activeHostName ?? this.activeHostName,
      hostIp: hostIp ?? this.hostIp,
      hostPort: hostPort ?? this.hostPort,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      offlineQueueCount: offlineQueueCount ?? this.offlineQueueCount,
      lastError: clearError ? null : (lastError ?? this.lastError),
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }
}

class ConnectionStateNotifier extends Notifier<ConnectionStateModel> {
  final WebSocketClient _wsClient = WebSocketClient();
  StreamSubscription<ConnectionStatus>? _statusSub;

  @override
  ConnectionStateModel build() {
    _initListeners();
    ref.onDispose(() {
      _statusSub?.cancel();
    });

    final currentStatus = _mapSocketStatus(_wsClient.status);
    return ConnectionStateModel(
      status: currentStatus,
      latencyMs: _wsClient.latencyNotifier.value,
      activeHostName: _wsClient.activeMachineName,
      lastUpdated: DateTime.now(),
    );
  }

  void _initListeners() {
    _statusSub = _wsClient.statusStream.listen((status) {
      final linkStatus = _mapSocketStatus(status);
      state = state.copyWith(
        status: linkStatus,
        activeHostName: _wsClient.activeMachineName,
        clearLatency: linkStatus != LinkStatus.connected,
      );
    });

    _wsClient.latencyNotifier.addListener(() {
      state = state.copyWith(
        latencyMs: _wsClient.latencyNotifier.value,
      );
    });
  }

  LinkStatus _mapSocketStatus(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return LinkStatus.connected;
      case ConnectionStatus.authenticating:
        return LinkStatus.authenticating;
      case ConnectionStatus.connecting:
        return LinkStatus.reconnecting;
      case ConnectionStatus.disconnected:
        return LinkStatus.disconnected;
    }
  }

  Future<void> connect({
    required String ip,
    required String port,
    String? pairingSecret,
  }) async {
    state = state.copyWith(
      status: LinkStatus.reconnecting,
      hostIp: ip,
      hostPort: port,
      clearError: true,
    );

    try {
      await _wsClient.connect(ip, port, pairingSecret);
      state = state.copyWith(
        status: LinkStatus.connected,
        reconnectAttempts: 0,
      );
    } catch (e) {
      state = state.copyWith(
        status: LinkStatus.disconnected,
        lastError: e.toString(),
      );
    }
  }

  void disconnect() {
    _wsClient.disconnect();
    state = state.copyWith(
      status: LinkStatus.disconnected,
      clearLatency: true,
    );
  }

  void updateOfflineQueueCount(int count) {
    state = state.copyWith(offlineQueueCount: count);
  }
}

final connectionStateProvider =
    NotifierProvider<ConnectionStateNotifier, ConnectionStateModel>(
  ConnectionStateNotifier.new,
);
