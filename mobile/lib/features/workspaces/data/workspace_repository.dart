import 'dart:async';
import '../../../core/network/websocket_client.dart';
import '../../../core/models/workspace.dart';

class WorkspaceRepository {
  final WebSocketClient _client = WebSocketClient();

  Future<List<Workspace>> getWorkspaces() async {
    if (_client.status != ConnectionStatus.connected) {
      return [];
    }

    final completer = Completer<List<Workspace>>();
    
    final subscription = _client.messageStream.listen((data) {
      if (data['type'] == 'workspaces_list') {
        final List<dynamic> payload = data['data'] ?? [];
        final workspaces = payload.map((e) => Workspace.fromJson(e)).toList();
        if (!completer.isCompleted) {
          completer.complete(workspaces);
        }
      }
    });

    try {
      _client.sendDataRequest('get_workspaces');
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
    }

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (!completer.isCompleted) completer.completeError(Exception('Timeout fetching workspaces'));
        return [];
      },
    ).whenComplete(() => subscription.cancel());
  }

  Stream<Workspace> get workspaceUpdates {
    return _client.messageStream
        .where((data) => data['type'] == 'workspace_updated')
        .map((data) => Workspace.fromJson(data['data']));
  }
}
