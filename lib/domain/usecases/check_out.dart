import '../repositories/attendance_repository.dart';
import '../../core/utils/result.dart';
import '../entities/attendance.dart';

class CheckOutUseCase {
  final AttendanceRepository repository;

  CheckOutUseCase(this.repository);

  Future<Result<Attendance>> call(String userId) {
    return repository.checkOut(userId);
  }
} 