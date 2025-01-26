class AttendanceRecord {
  final String id;
  final String userId;
  final DateTime? date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AttendanceRecord({
    required this.id,
    required this.userId,
    this.date,
    this.checkIn,
    this.checkOut,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date?.toIso8601String(),
      'check_in': checkIn?.toIso8601String(),
      'check_out': checkOut?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      checkIn: json['check_in'] != null ? DateTime.parse(json['check_in'] as String) : null,
      checkOut: json['check_out'] != null ? DateTime.parse(json['check_out'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  AttendanceRecord copyWith({
    String? id,
    String? userId,
    DateTime? date,
    DateTime? checkIn,
    DateTime? checkOut,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'AttendanceRecord(id: $id, userId: $userId, date: $date, checkIn: $checkIn, checkOut: $checkOut)';
  }
}