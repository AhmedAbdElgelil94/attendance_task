import '../../core/entities/entity.dart';

class Attendance extends Entity {
  final String id;
  final String userId;
  final DateTime? date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final Duration? duration;

  const Attendance({
    required this.id,
    required this.userId,
    this.date,
    this.checkIn,
    this.checkOut,
    this.duration,
  });
} 