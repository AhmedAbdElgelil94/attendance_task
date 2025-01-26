import '../repositories/attendance_repository.dart';
import '../../core/utils/result.dart';
import '../entities/attendance.dart';

class CheckInUseCase {
  final AttendanceRepository repository;

  CheckInUseCase(this.repository);

  Future<Result<Attendance>> call(String userId) {
    return repository.checkIn(userId);
  }
} 