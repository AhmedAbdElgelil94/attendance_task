import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/attendance_record.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'attendance.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE,
        password TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_records (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        date TEXT,
        check_in TEXT,
        check_out TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  Future<int> insertUser(User user) async {
    final db = await database;
    final values = user.toJson();
    return await db.insert('users', values);
  }

  Future<User?> getUser(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return User.fromJson(maps.first);
  }

  Future<int> insertAttendanceRecord(AttendanceRecord record) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final values = record.toJson()
      ..addAll({
        'created_at': now,
        'updated_at': now,
      });
    
    return await db.insert('attendance_records', values);
  }

  Future<int> updateAttendanceRecord(AttendanceRecord record) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    
    final values = record.toJson()
      ..addAll({
        'updated_at': now,
      });
    
    return await db.update(
      'attendance_records',
      values,
      where: 'date = ? AND user_id = ?',
      whereArgs: [record.date?.toIso8601String(), record.userId],
    );
  }

  Future<List<AttendanceRecord>> getAttendanceRecords(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC, created_at DESC',
    );

    return List.generate(maps.length, (i) => AttendanceRecord.fromJson(maps[i]));
  }

  Future<AttendanceRecord?> getTodayAttendance(String userId) async {
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
    return AttendanceRecord.fromJson(maps.first);
  }

  Future<List<AttendanceRecord>> getAttendance({required String userId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => AttendanceRecord.fromJson(maps[i]));
  }
}