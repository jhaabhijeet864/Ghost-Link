import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class CryptoManager {
  final _storage = const FlutterSecureStorage();
  final _ed25519 = Ed25519();

  Future<SimpleKeyPair> getOrCreateKeyPair() async {
    final privateKeyStr = await _storage.read(key: 'private_key');
    if (privateKeyStr != null) {
      final privateKeyBytes = base64Decode(privateKeyStr);
      return await _ed25519.newKeyPairFromSeed(privateKeyBytes);
    } else {
      final keyPair = await _ed25519.newKeyPair();
      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
      await _storage.write(key: 'private_key', value: base64Encode(privateKeyBytes));
      return keyPair;
    }
  }

  Future<String> signToken(String token) async {
    final keyPair = await getOrCreateKeyPair();
    final signature = await _ed25519.sign(utf8.encode(token), keyPair: keyPair);
    return base64Encode(signature.bytes);
  }

  Future<void> deleteKey() async {
    await _storage.delete(key: 'private_key');
  }
}
