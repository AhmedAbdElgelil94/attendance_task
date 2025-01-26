import 'package:hive/hive.dart';
import '../../domain/entities/attendance.dart';

part 'attendance_hive_model.g.dart';

@HiveType(typeId: 0)
class AttendanceHiveModel extends Attendance {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String userId;

  @HiveField(2)
  @override
  final DateTime? date;

  @HiveField(3)
  @override
  final DateTime? checkIn;

  @HiveField(4)
  @override
  final DateTime? checkOut;

  @HiveField(5)
  @override
  final Duration? duration;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  AttendanceHiveModel({
    required this.id,
    required this.userId,
    this.date,
    this.checkIn,
    this.checkOut,
    this.duration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       super(
         id: id,
         userId: userId,
         date: date,
         checkIn: checkIn,
         checkOut: checkOut,
         duration: duration,
       );

  factory AttendanceHiveModel.fromJson(Map<String, dynamic> json) {
    return AttendanceHiveModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      checkIn: json['check_in'] != null ? DateTime.parse(json['check_in'] as String) : null,
      checkOut: json['check_out'] != null ? DateTime.parse(json['check_out'] as String) : null,
      duration: json['duration'] != null ? Duration(milliseconds: json['duration'] as int) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Add a factory constructor for Hive
  factory AttendanceHiveModel.empty() {
    return AttendanceHiveModel(
      id: '',
      userId: '',
      date: DateTime.now(),
    );
  }
} 