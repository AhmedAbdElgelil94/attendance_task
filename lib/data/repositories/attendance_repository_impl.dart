import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_hive_model.dart';
import '../datasources/attendance_hive_datasource.dart';
import '../network/network_info.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceHiveDataSource hiveDataSource;
  final SharedPreferences cache;
  final NetworkInfo networkInfo;
  final Connectivity connectivity;

  static const String cachedAttendanceKey = 'CACHED_ATTENDANCE';
  static const Duration cacheDuration = Duration(minutes: 15);
  static const int pageSize = 20;

  AttendanceRepositoryImpl({
    required this.hiveDataSource,
    required this.cache,
    required this.networkInfo,
    required this.connectivity,
  }) {
    _setupConnectivityStream();
  }

  void _setupConnectivityStream() {
    connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        _syncPendingRecords();
      }
    });
  }

  @override
  Future<Result<List<Attendance>>> getAttendanceRecords(String userId, {int page = 0}) async {
    try {
      final offset = page * pageSize;
      final records = await hiveDataSource.getAttendanceRecords(userId, limit: pageSize, offset: offset);
      return Success(records);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<Attendance>> checkIn(String userId) async {
    try {
      final now = DateTime.now();
      final record = AttendanceHiveModel(
        id: now.millisecondsSinceEpoch.toString(),
        userId: userId,
        date: now,
        checkIn: now,
      );

      await hiveDataSource.insertAttendanceRecord(record);
      
      if (await networkInfo.isConnected) {
        // Sync with remote server
        await _syncRecord(record);
      } else {
        await _markRecordForSync(record);
      }
      
      return Success(record);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<Attendance>> checkOut(String userId) async {
    try {
      final today = await hiveDataSource.getTodayAttendance(userId);
      if (today == null) {
        return Error(const DatabaseFailure('No check-in record found for today'));
      }

      final now = DateTime.now();
      final updatedRecord = AttendanceHiveModel(
        id: today.id,
        userId: today.userId,
        date: today.date,
        checkIn: today.checkIn,
        checkOut: now,
        duration: now.difference(today.checkIn!),
      );

      await hiveDataSource.updateAttendanceRecord(updatedRecord);
      
      if (await networkInfo.isConnected) {
        await _syncRecord(updatedRecord);
      } else {
        await _markRecordForSync(updatedRecord);
      }
      
      return Success(updatedRecord);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Result<Attendance?>> getTodayAttendance(String userId) async {
    try {
      final record = await hiveDataSource.getTodayAttendance(userId);
      return Success(record);
    } catch (e) {
      return Error(DatabaseFailure(e.toString()));
    }
  }

  Future<void> _syncRecord(AttendanceHiveModel record) async {
    // TODO: Implement sync with remote server
  }

  Future<void> _markRecordForSync(AttendanceHiveModel record) async {
    final pendingSync = cache.getStringList('pending_sync') ?? [];
    pendingSync.add(json.encode(record.toJson()));
    await cache.setStringList('pending_sync', pendingSync);
  }

  Future<void> _syncPendingRecords() async {
    final pendingSync = cache.getStringList('pending_sync') ?? [];
    if (pendingSync.isEmpty) return;

    for (var recordJson in pendingSync) {
      final record = AttendanceHiveModel.fromJson(json.decode(recordJson));
      try {
        await _syncRecord(record);
        pendingSync.remove(recordJson);
      } catch (e) {
        // Keep record in pending sync if sync fails
        continue;
      }
    }

    await cache.setStringList('pending_sync', pendingSync);
  }

  Future<void> cleanOldRecords() async {
    await hiveDataSource.deleteOldRecords(const Duration(days: 30));
  }
} 