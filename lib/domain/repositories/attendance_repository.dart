import '../entities/attendance.dart';
import '../../core/utils/result.dart';

abstract class AttendanceRepository {
  Future<Result<List<Attendance>>> getAttendanceRecords(String userId, {int page = 0});
  Future<Result<Attendance>> checkIn(String userId);
  Future<Result<Attendance>> checkOut(String userId);
  Future<Result<Attendance?>> getTodayAttendance(String userId);
} 