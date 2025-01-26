import 'package:hive_flutter/hive_flutter.dart';
import '../models/attendance_hive_model.dart';

class AttendanceHiveDataSource {
  static const String boxName = 'attendance_records';
  final Box<AttendanceHiveModel> _box;

  AttendanceHiveDataSource(this._box);

  static Future<AttendanceHiveDataSource> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(AttendanceHiveModelAdapter());
    final box = await Hive.openBox<AttendanceHiveModel>(boxName);
    return AttendanceHiveDataSource(box);
  }

  Future<List<AttendanceHiveModel>> getAttendanceRecords(String userId, {int limit = 20, int offset = 0}) async {
    final records = _box.values
        .where((record) => record.userId == userId)
        .toList()
      ..sort((a, b) => b.date?.compareTo(a.date ?? DateTime.now()) ?? 0);
    
    final endIndex = (offset + limit) > records.length ? records.length : offset + limit;
    return records.sublist(offset, endIndex);
  }

  Future<AttendanceHiveModel?> getTodayAttendance(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _box.values.firstWhere(
      (record) => record.userId == userId &&
          record.date != null &&
          record.date!.isAfter(startOfDay) &&
          record.date!.isBefore(endOfDay),
      orElse: () => throw Exception('No record found'),
    );
  }

  Future<void> insertAttendanceRecord(AttendanceHiveModel record) async {
    await _box.put(record.id, record);
  }

  Future<void> updateAttendanceRecord(AttendanceHiveModel record) async {
    await _box.put(record.id, record);
  }

  Future<int> getRecordCount(String userId) async {
    return _box.values.where((record) => record.userId == userId).length;
  }

  Future<void> deleteOldRecords(Duration threshold) async {
    final cutoffDate = DateTime.now().subtract(threshold);
    final oldRecords = _box.values.where((record) => record.date?.isBefore(cutoffDate) ?? false);
    
    for (var record in oldRecords) {
      await _box.delete(record.id);
    }
  }
} 