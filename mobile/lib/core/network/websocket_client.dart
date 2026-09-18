import 'dart:io';
import '../security/crypto_manager.dart';
import '../../data/database/app_database.dart';
import 'dart:convert';

class WebSocketClient {
  WebSocket? _socket;
  final CryptoManager _cryptoManager = CryptoManager();
  final AppDatabase _db = AppDatabase();

  Future<void> connect(String ip, String port, String token) async {
    final signature = await _cryptoManager.signToken(token);
    final uri = Uri.parse('ws://$ip:$port?token=$token');

    _socket = await WebSocket.connect(uri.toString(), headers: {
      'X-LocalLoop-Signature': signature,
    });
    
    _socket!.listen((message) async {
      try {
        final Map<String, dynamic> event = jsonDecode(message);
        await _db.insertEvent(event);
      } catch (e) {
        // Handle json parse error or DB error
      }
    });
  }

  void disconnect() {
    _socket?.close();
  }
}
