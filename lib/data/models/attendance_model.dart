import '../../domain/entities/attendance.dart';

class AttendanceModel extends Attendance {
  AttendanceModel({
    required String id,
    required String userId,
    DateTime? date,
    DateTime? checkIn,
    DateTime? checkOut,
    Duration? duration,
  }) : super(
          id: id,
          userId: userId,
          date: date,
          checkIn: checkIn,
          checkOut: checkOut,
          duration: duration,
        );

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      checkIn: json['check_in'] != null ? DateTime.parse(json['check_in'] as String) : null,
      checkOut: json['check_out'] != null ? DateTime.parse(json['check_out'] as String) : null,
      duration: json['duration'] != null ? Duration(milliseconds: json['duration'] as int) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date?.toIso8601String(),
      'check_in': checkIn?.toIso8601String(),
      'check_out': checkOut?.toIso8601String(),
      'duration': duration?.inMilliseconds,
    };
  }
} 