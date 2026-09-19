import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedDevice {
  final String id;
  final String name;
  String ip;
  String port;
  final String? machineName;
  DateTime? lastConnected;

  SavedDevice({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    this.machineName,
    this.lastConnected,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ip': ip,
        'port': port,
        'machineName': machineName,
        'lastConnected': lastConnected?.toIso8601String(),
      };

  factory SavedDevice.fromJson(Map<String, dynamic> json) => SavedDevice(
        id: json['id'] as String,
        name: json['name'] as String,
        ip: json['ip'] as String,
        port: json['port'] as String,
        machineName: json['machineName'] as String?,
        lastConnected: json['lastConnected'] != null
            ? DateTime.tryParse(json['lastConnected'] as String)
            : null,
      );
}

class DeviceManager {
  final _storage = const FlutterSecureStorage();
  static const _devicesKey = 'saved_devices';

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

  Future<List<SavedDevice>> getSavedDevices() async {
    final str = await _read(_devicesKey);
    if (str == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(str);
      return jsonList.map((e) => SavedDevice.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDevice(SavedDevice device) async {
    final devices = await getSavedDevices();
    final index = devices.indexWhere((d) => d.id == device.id);

    if (index >= 0) {
      devices[index] = device;
    } else {
      devices.add(device);
    }

    await _write(_devicesKey, jsonEncode(devices.map((d) => d.toJson()).toList()));
  }

  Future<void> updateDeviceAddress(String id, String newIp, String newPort) async {
    final devices = await getSavedDevices();
    final index = devices.indexWhere((d) => d.id == id);
    if (index >= 0) {
      devices[index].ip = newIp;
      devices[index].port = newPort;
      devices[index].lastConnected = DateTime.now();
      await _write(_devicesKey, jsonEncode(devices.map((d) => d.toJson()).toList()));
    }
  }

  Future<void> removeDevice(String id) async {
    final devices = await getSavedDevices();
    devices.removeWhere((d) => d.id == id);
    await _write(_devicesKey, jsonEncode(devices.map((d) => d.toJson()).toList()));
  }
}
