import 'dart:io';
import '../security/crypto_manager.dart';
import '../../data/database/app_database.dart';
import 'dart:convert';
import 'dart:async';

class WebSocketClient {
  WebSocket? _socket;
  final CryptoManager _cryptoManager = CryptoManager();
  final AppDatabase _db = AppDatabase();
  
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _approvalController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get approvalStream => _approvalController.stream;

  Future<void> connect(String ip, String port, String token) async {
    final signature = await _cryptoManager.signToken(token);
    final uri = Uri.parse('ws://$ip:$port?token=$token');

    _socket = await WebSocket.connect(uri.toString(), headers: {
      'X-LocalLoop-Signature': signature,
    });
    
    _socket!.listen((message) async {
      try {
        final Map<String, dynamic> data = jsonDecode(message);
        final type = data['type'] as String?;
        
        if (type == 'approval_request') {
          _approvalController.add(data);
        } else {
          _messageController.add(data);
          await _db.insertEvent(data);
        }
      } catch (e) {
        // Handle json parse error or DB error
      }
    });
  }

  Future<void> sendCommand(Map<String, dynamic> command) async {
    _socket?.add(jsonEncode(command));
  }

  Future<void> sendApprovalResponse(Map<String, dynamic> response) async {
    _socket?.add(jsonEncode(response));
  }

  void disconnect() {
    _socket?.close();
    _messageController.close();
    _approvalController.close();
  }
}
