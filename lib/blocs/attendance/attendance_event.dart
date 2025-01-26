abstract class AttendanceEvent {}

class LoadAttendanceEvent extends AttendanceEvent {}

class MarkAttendanceEvent extends AttendanceEvent {
  final bool isCheckIn;
  final String userId;

  MarkAttendanceEvent({
    required this.isCheckIn,
    required this.userId,
  });
}

// Legacy events for database operations
class CheckInEvent extends AttendanceEvent {
  final String userId;

  CheckInEvent(this.userId);
}

class CheckOutEvent extends AttendanceEvent {
  final String userId;

  CheckOutEvent(this.userId);
}

class LoadAttendanceRecordsEvent extends AttendanceEvent {
  final String userId;

  LoadAttendanceRecordsEvent(this.userId);
}

class FetchAttendanceEvent extends AttendanceEvent {
  final String userId;

  FetchAttendanceEvent({required this.userId});
} 