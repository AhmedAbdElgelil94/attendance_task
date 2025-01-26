import '../repositories/attendance_repository.dart';
import '../../core/utils/result.dart';
import '../entities/attendance.dart';

class GetAttendanceUseCase {
  final AttendanceRepository repository;

  const GetAttendanceUseCase(this.repository);

  Future<Result<List<Attendance>>> call(String userId, {int page = 0}) async {
    return await repository.getAttendanceRecords(userId, page: page);
  }
} 