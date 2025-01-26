// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AttendanceHiveModelAdapter extends TypeAdapter<AttendanceHiveModel> {
  @override
  final int typeId = 0;

  @override
  AttendanceHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AttendanceHiveModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      date: fields[2] as DateTime?,
      checkIn: fields[3] as DateTime?,
      checkOut: fields[4] as DateTime?,
      duration: fields[5] as Duration?,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AttendanceHiveModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.checkIn)
      ..writeByte(4)
      ..write(obj.checkOut)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
