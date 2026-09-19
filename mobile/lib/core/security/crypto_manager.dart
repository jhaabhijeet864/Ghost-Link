import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CryptoManager {
  final _storage = const FlutterSecureStorage();
  final _ed25519 = Ed25519();

  Future<String?> _read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    try {
      return await _storage.read(key: key);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      return;
    }
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  Future<void> _delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      return;
    }
    try {
      await _storage.delete(key: key);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }

  Future<SimpleKeyPair> getOrCreateKeyPair() async {
    final privateKeyStr = await _read('private_key');
    if (privateKeyStr != null) {
      final privateKeyBytes = base64Decode(privateKeyStr);
      return await _ed25519.newKeyPairFromSeed(privateKeyBytes);
    } else {
      final keyPair = await _ed25519.newKeyPair();
      final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
      await _write('private_key', base64Encode(privateKeyBytes));
      return keyPair;
    }
  }

  Future<String> getPublicKeyBase64() async {
    final keyPair = await getOrCreateKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    return base64Encode(publicKey.bytes);
  }

  Future<String> signToken(String token) async {
    final keyPair = await getOrCreateKeyPair();
    final signature = await _ed25519.sign(utf8.encode(token), keyPair: keyPair);
    return base64Encode(signature.bytes);
  }

  Future<void> deleteKey() async {
    await _delete('private_key');
  }
}
