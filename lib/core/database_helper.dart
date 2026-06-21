import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('predictions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE predictions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        image_path TEXT NOT NULL,
        gender TEXT NOT NULL,
        age TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add userId column to existing table
      await db.execute(
        'ALTER TABLE predictions ADD COLUMN userId TEXT DEFAULT ""',
      );
    }
  }

  /// Get the current user's UID, or empty string if not logged in
  String _getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<int> insertPrediction(Map<String, dynamic> row) async {
    final db = await instance.database;
    // Always include the current user's ID
    row['userId'] = _getCurrentUserId();
    return await db.insert('predictions', row);
  }

  Future<List<Map<String, dynamic>>> getAllPredictions() async {
    final db = await instance.database;
    final userId = _getCurrentUserId();
    return await db.query(
      'predictions',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
  }

  Future<int> deletePrediction(int id) async {
    final db = await instance.database;
    final userId = _getCurrentUserId();
    // Only delete if it belongs to the current user
    return await db.delete(
      'predictions',
      where: 'id = ? AND userId = ?',
      whereArgs: [id, userId],
    );
  }

  Future<void> clearAllHistory() async {
    final db = await instance.database;
    final userId = _getCurrentUserId();
    // Only clear records for the current user
    await db.delete('predictions', where: 'userId = ?', whereArgs: [userId]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
