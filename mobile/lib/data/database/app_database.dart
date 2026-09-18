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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY,
            session_id TEXT,
            type TEXT,
            timestamp TEXT,
            payload TEXT
          )
        ''');
      },
    );
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

  Future<List<Map<String, dynamic>>> getEvents() async {
    final db = await database;
    return await db.query('events', orderBy: 'id DESC');
  }
}
