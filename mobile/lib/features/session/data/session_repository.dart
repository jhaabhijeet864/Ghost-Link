import 'dart:async';
import '../../../core/network/websocket_client.dart';
import '../../../core/models/active_agent_session.dart';

class SessionRepository {
  final WebSocketClient _client = WebSocketClient();

  Future<List<ActiveAgentSession>> getSessions() async {
    if (_client.status != ConnectionStatus.connected) {
      return [];
    }

    final completer = Completer<List<ActiveAgentSession>>();
    
    final subscription = _client.messageStream.listen((data) {
      if (data['type'] == 'sessions_list') {
        final List<dynamic> payload = data['data'] ?? [];
        final sessions = payload.map((e) => ActiveAgentSession.fromJson(e)).toList();
        if (!completer.isCompleted) {
          completer.complete(sessions);
        }
      }
    });

    try {
      _client.sendDataRequest('get_sessions');
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
    }

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (!completer.isCompleted) completer.completeError(Exception('Timeout fetching sessions'));
        return [];
      },
    ).whenComplete(() => subscription.cancel());
  }

  Stream<ActiveAgentSession> get sessionUpdates {
    return _client.messageStream
        .where((data) => data['type'] == 'session_updated')
        .map((data) => ActiveAgentSession.fromJson(data['data']));
  }
}
