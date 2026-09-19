import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'localloop.db');
    return await openDatabase(
      path,
      version: 3,
      onConfigure: (db) async {
        await db.execute('PRAGMA journal_mode = WAL');
        await db.execute('PRAGMA synchronous = NORMAL');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createTables(db);
        }
        if (oldVersion < 3) {
          await _createIndexes(db);
        }
      },
    );
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_events_session ON events (session_id, timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cmd_device ON command_history (device_id, timestamp)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_approval_device ON approval_history (device_id, timestamp)');
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS events (
        id INTEGER PRIMARY KEY,
        session_id TEXT,
        type TEXT,
        timestamp TEXT,
        payload TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS command_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT,
        intent_id TEXT,
        input TEXT,
        action TEXT,
        target TEXT,
        risk_level TEXT,
        status TEXT,
        result TEXT,
        timestamp TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS approval_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT,
        intent_id TEXT,
        action TEXT,
        target TEXT,
        risk_level TEXT,
        user_decision TEXT,
        result TEXT,
        timestamp TEXT
      )
    ''');
  }

  Future<void> insertEvent(Map<String, dynamic> event) async {
    final db = await database;
    await db.insert('events', {
      'id': event['id'],
      'session_id': event['session_id'],
      'type': event['type'],
      'timestamp': event['timestamp'],
      'payload': jsonEncode(event['payload']),
    });
  }

  Future<void> insertEventsBatch(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final event in items) {
      batch.insert('events', {
        'id': event['id'],
        'session_id': event['session_id'],
        'type': event['type'],
        'timestamp': event['timestamp'],
        'payload': jsonEncode(event['payload']),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    final db = await database;
    return await db.query('events', orderBy: 'id DESC');
  }

  Future<void> insertCommandHistory(Map<String, dynamic> command) async {
    final db = await database;
    await db.insert('command_history', {
      'device_id': command['deviceId'],
      'intent_id': command['intentId'],
      'input': command['input'],
      'action': command['action'],
      'target': command['target'],
      'risk_level': command['riskLevel'],
      'status': command['status'],
      'result': command['result'],
      'timestamp': command['timestamp'],
    });
  }

  Future<List<Map<String, dynamic>>> getCommandHistory(String deviceId) async {
    final db = await database;
    return await db.query(
      'command_history',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      orderBy: 'timestamp DESC',
      limit: 100,
    );
  }

  Future<void> insertApprovalHistory(Map<String, dynamic> approval) async {
    final db = await database;
    await db.insert('approval_history', {
      'device_id': approval['deviceId'],
      'intent_id': approval['intentId'],
      'action': approval['action'],
      'target': approval['target'],
      'risk_level': approval['riskLevel'],
      'user_decision': approval['userDecision'],
      'result': approval['result'],
      'timestamp': approval['timestamp'],
    });
  }

  Future<List<Map<String, dynamic>>> getApprovalHistory(String deviceId) async {
    final db = await database;
    return await db.query(
      'approval_history',
      where: 'device_id = ?',
      whereArgs: [deviceId],
      orderBy: 'timestamp DESC',
      limit: 100,
    );
  }
}
