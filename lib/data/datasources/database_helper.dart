import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/attendance_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'attendance_database.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_records(
        id TEXT PRIMARY KEY,
        user_id TEXT,
        date TEXT,
        check_in TEXT,
        check_out TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('DROP TABLE IF EXISTS attendance_records');
      await db.execute('''
        CREATE TABLE attendance_records(
          id TEXT PRIMARY KEY,
          user_id TEXT,
          date TEXT,
          check_in TEXT,
          check_out TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )
      ''');
    }
  }

  Future<List<AttendanceModel>> getAttendanceRecords(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, created_at DESC',
    );

    return List.generate(maps.length, (i) => AttendanceModel.fromJson(maps[i]));
  }

  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_records',
      where: 'user_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [userId, startOfDay, endOfDay],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return AttendanceModel.fromJson(maps.first);
  }

  Future<int> insertAttendanceRecord(AttendanceModel record) async {
    final db = await database;
    return await db.insert('attendance_records', record.toJson());
  }

  Future<int> updateAttendanceRecord(AttendanceModel record) async {
    final db = await database;
    return await db.update(
      'attendance_records',
      record.toJson(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }
} 