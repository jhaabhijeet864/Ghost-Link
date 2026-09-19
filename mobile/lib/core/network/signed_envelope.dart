import 'dart:convert';
import '../security/crypto_manager.dart';

class SignedEnvelope {
  final CryptoManager _cryptoManager;
  SignedEnvelope(this._cryptoManager);

  Future<Map<String, dynamic>> seal(String actionType, Map<String, dynamic> payload) async {
    final int timestamp = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final String publicKey = await _cryptoManager.getPublicKeyBase64();

    final Map<String, dynamic> unsignedBody = {
      'type': actionType,
      'timestamp': timestamp,
      'payload': payload,
      'publicKey': publicKey,
    };

    final String canonicalJson = jsonEncode(unsignedBody);
    final String signature = await _cryptoManager.signToken(canonicalJson);

    return {
      'body': unsignedBody,
      'signature': signature,
    };
  }
}
