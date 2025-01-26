import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/database_helper.dart';
import '../../models/attendance_record.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';
import '../../services/biometric_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final DatabaseHelper _databaseHelper;
  final BiometricService _biometricService;
  final SharedPreferences _prefs;
  static const String _attendanceKey = 'attendance_records';

  AttendanceBloc(this._databaseHelper, this._biometricService, this._prefs)
      : super(AttendanceInitial()) {
    on<CheckInEvent>(_onCheckIn);
    on<CheckOutEvent>(_onCheckOut);
    on<LoadAttendanceRecordsEvent>(_onLoadRecords);
    on<LoadAttendanceEvent>(_onLoadAttendance);
    on<MarkAttendanceEvent>(_onMarkAttendance);
    on<FetchAttendanceEvent>(_onFetchAttendance);
  }

  Future<void> _onCheckIn(CheckInEvent event, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading());
    try {
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) {
        emit(AttendanceError('Biometric authentication failed'));
        return;
      }

      final today = await _databaseHelper.getTodayAttendance(event.userId);
      if (today != null) {
        emit(AttendanceError('Already checked in for today'));
        return;
      }

      final record = AttendanceRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: event.userId,
        date: DateTime.now(),
        checkIn: DateTime.now(),
      );

      await _databaseHelper.insertAttendanceRecord(record);
      add(LoadAttendanceRecordsEvent(event.userId));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _onCheckOut(CheckOutEvent event, Emitter<AttendanceState> emit) async {
    emit(AttendanceLoading());
    try {
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) {
        emit(AttendanceError('Biometric authentication failed'));
        return;
      }

      final today = await _databaseHelper.getTodayAttendance(event.userId);
      if (today == null) {
        emit(AttendanceError('No check-in record found for today'));
        return;
      }

      if (today.checkOut != null) {
        emit(AttendanceError('Already checked out for today'));
        return;
      }

      final updatedRecord = today.copyWith(
        checkOut: DateTime.now(),
      );

      await _databaseHelper.updateAttendanceRecord(updatedRecord);
      add(LoadAttendanceRecordsEvent(event.userId));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _onLoadRecords(
    LoadAttendanceRecordsEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final records = await _databaseHelper.getAttendanceRecords(event.userId);
      emit(AttendanceLoaded(records));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  Future<void> _onLoadAttendance(
    LoadAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final records = _loadRecords();
      emit(AttendanceLoaded(records));
    } catch (e) {
      emit(AttendanceError('Failed to load attendance records'));
    }
  }

  Future<void> _onMarkAttendance(
    MarkAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final records = _loadRecords();
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      // Find today's record
      final todayRecord = records.firstWhere(
        (record) => _isSameDay(record.date, todayDate),
        orElse: () => AttendanceRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: event.userId,
          date: todayDate,
        ),
      );

      // Check if can mark attendance
      if (event.isCheckIn && todayRecord.checkIn != null) {
        emit(AttendanceError('Already checked in today'));
        return;
      }
      if (!event.isCheckIn && todayRecord.checkOut != null) {
        emit(AttendanceError('Already checked out today'));
        return;
      }
      if (!event.isCheckIn && todayRecord.checkIn == null) {
        emit(AttendanceError('Must check in first'));
        return;
      }

      // Update record
      final updatedRecord = todayRecord.copyWith(
        checkIn: event.isCheckIn ? today : todayRecord.checkIn,
        checkOut: event.isCheckIn ? todayRecord.checkOut : today,
      );

      // Update records list
      final updatedRecords = List<AttendanceRecord>.from(records);
      final existingIndex = records.indexWhere(
        (record) => _isSameDay(record.date, todayDate),
      );
      if (existingIndex >= 0) {
        updatedRecords[existingIndex] = updatedRecord;
      } else {
        updatedRecords.add(updatedRecord);
      }

      // Save and emit
      await _saveRecords(updatedRecords);
      emit(AttendanceLoaded(updatedRecords));
    } catch (e) {
      emit(AttendanceError('Failed to mark attendance'));
    }
  }

  Future<void> _onFetchAttendance(
    FetchAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      emit(AttendanceLoading());
      final records = await _databaseHelper.getAttendance(userId: event.userId);
      emit(AttendanceLoaded(records));
    } catch (e) {
      emit(AttendanceError(e.toString()));
    }
  }

  List<AttendanceRecord> _loadRecords() {
    final jsonString = _prefs.getString(_attendanceKey);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList
        .map((json) => AttendanceRecord.fromJson(json as Map<String, dynamic>))
        .toList()
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      }); // Sort by date descending
  }

  Future<void> _saveRecords(List<AttendanceRecord> records) async {
    final jsonList = records.map((record) => record.toJson()).toList();
    await _prefs.setString(_attendanceKey, jsonEncode(jsonList));
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
} 