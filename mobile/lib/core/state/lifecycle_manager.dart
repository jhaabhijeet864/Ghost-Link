import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/websocket_client.dart';

class AppLifecycleManager with WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  final WebSocketClient _wsClient = WebSocketClient();
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    if (!_isInitialized) return;
    WidgetsBinding.instance.removeObserver(this);
    _isInitialized = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When user returns to the app, if disconnected, trigger immediate reconnect
      if (_wsClient.status == ConnectionStatus.disconnected) {
        _wsClient.connect(
          _wsClient.lastIp ?? '127.0.0.1',
          _wsClient.lastPort ?? '8080',
          _wsClient.lastPairingSecret,
        ).catchError((_) {});
      }
    }
  }
}
