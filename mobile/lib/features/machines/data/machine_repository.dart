import 'dart:async';
import '../../../core/network/websocket_client.dart';
import '../../../core/models/machine.dart';

class MachineRepository {
  final WebSocketClient _client = WebSocketClient();

  /// Fetches the list of machines from the backend.
  Future<List<Machine>> getMachines() async {
    if (_client.status != ConnectionStatus.connected) {
      // Return a fallback or throw depending on how we want to handle offline mode
      return [];
    }

    final completer = Completer<List<Machine>>();
    
    // Listen for the response
    final subscription = _client.messageStream.listen((data) {
      if (data['type'] == 'machines_list') {
        final List<dynamic> payload = data['data'] ?? [];
        final machines = payload.map((e) => Machine.fromJson(e)).toList();
        if (!completer.isCompleted) {
          completer.complete(machines);
        }
      }
    });

    // Send the request
    try {
      _client.sendDataRequest('get_machines');
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
    }

    // Timeout to prevent hanging forever
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (!completer.isCompleted) completer.completeError(Exception('Timeout fetching machines'));
        return [];
      },
    ).whenComplete(() => subscription.cancel());
  }

  /// Stream of real-time machine updates (if the backend pushes them)
  Stream<Machine> get machineUpdates {
    return _client.messageStream
        .where((data) => data['type'] == 'machine_updated')
        .map((data) => Machine.fromJson(data['data']));
  }
}
