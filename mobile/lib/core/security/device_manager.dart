import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

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

  Future<List<SavedDevice>> getSavedDevices() async {
    final str = await _storage.read(key: _devicesKey);
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

    await _storage.write(key: _devicesKey, value: jsonEncode(devices.map((d) => d.toJson()).toList()));
  }

  Future<void> updateDeviceAddress(String id, String newIp, String newPort) async {
    final devices = await getSavedDevices();
    final index = devices.indexWhere((d) => d.id == id);
    if (index >= 0) {
      devices[index].ip = newIp;
      devices[index].port = newPort;
      devices[index].lastConnected = DateTime.now();
      await _storage.write(key: _devicesKey, value: jsonEncode(devices.map((d) => d.toJson()).toList()));
    }
  }

  Future<void> removeDevice(String id) async {
    final devices = await getSavedDevices();
    devices.removeWhere((d) => d.id == id);
    await _storage.write(key: _devicesKey, value: jsonEncode(devices.map((d) => d.toJson()).toList()));
  }
}
