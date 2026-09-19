import 'dart:async';
import 'app_database.dart';

class TelemetryIngestQueue {
  static final TelemetryIngestQueue _instance = TelemetryIngestQueue._internal();
  factory TelemetryIngestQueue() => _instance;
  TelemetryIngestQueue._internal();

  final List<Map<String, dynamic>> _batch = [];
  DateTime _lastFlush = DateTime.now();
  Timer? _flushTimer;

  void enqueue(Map<String, dynamic> event) {
    _batch.add(event);

    _flushTimer ??= Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_batch.isNotEmpty) {
        flush();
      }
    });

    if (_batch.length >= 25 || DateTime.now().difference(_lastFlush).inMilliseconds > 250) {
      flush();
    }
  }

  Future<void> flush() async {
    if (_batch.isEmpty) return;
    final toWrite = List<Map<String, dynamic>>.from(_batch);
    _batch.clear();
    _lastFlush = DateTime.now();

    try {
      await AppDatabase().insertEventsBatch(toWrite);
    } catch (_) {
      // Ignore background write errors
    }
  }

  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
    flush();
  }
}
