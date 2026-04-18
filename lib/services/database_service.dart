import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_result.dart';

/// Service for SQLite database operations (CRUD for scan results).
class DatabaseService {
  // Singleton pattern so the same DB instance is shared across the app.
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  /// Get the database instance, initializing it if needed.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the SQLite database and create the table.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vision_ai.db');

    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  /// Create the scan_results table on first database creation.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scan_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        resultData TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  /// Insert a new scan result. Returns the inserted row ID.
  Future<int> insertResult(ScanResult result) async {
    final db = await database;
    return db.insert('scan_results', result.toMap());
  }

  /// Get all scan results, ordered by most recent first.
  Future<List<ScanResult>> getResults() async {
    final db = await database;
    final maps = await db.query('scan_results', orderBy: 'timestamp DESC');
    return maps.map((m) => ScanResult.fromMap(m)).toList();
  }

  /// Delete a scan result by ID. Returns the number of rows deleted.
  Future<int> deleteResult(int id) async {
    final db = await database;
    return db.delete('scan_results', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete all scan results. Returns the number of rows deleted.
  Future<int> clearResults() async {
    final db = await database;
    return db.delete('scan_results');
  }

  /// Delete the image file associated with a scan result.
  Future<void> deleteImageFile(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
