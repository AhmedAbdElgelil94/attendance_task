import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/usecases/get_attendance.dart';
import '../../domain/usecases/check_in.dart';
import '../../domain/usecases/check_out.dart';
import '../../domain/services/notification_service.dart';

class AttendanceViewModel extends ChangeNotifier {
  final GetAttendanceUseCase getAttendanceUseCase;
  final CheckInUseCase checkInUseCase;
  final CheckOutUseCase checkOutUseCase;
  final Connectivity connectivity;
  final NotificationService notificationService;

  List<Attendance> _records = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  Failure? _error;
  bool _hasReachedMax = false;
  int _currentPage = 0;
  bool _isOnline = true;

  List<Attendance> get records => _records;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  Failure? get error => _error;
  bool get hasReachedMax => _hasReachedMax;
  bool get isOnline => _isOnline;

  AttendanceViewModel({
    required this.getAttendanceUseCase,
    required this.checkInUseCase,
    required this.checkOutUseCase,
    required this.connectivity,
    required this.notificationService,
  }) {
    _setupConnectivity();
  }

  Future<void> _setupConnectivity() async {
    _isOnline = await connectivity.checkConnectivity() != ConnectivityResult.none;
    connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
      if (_isOnline && _error is NetworkFailure) {
        loadAttendanceRecords(_records.first.userId);
      }
      notifyListeners();
    });
  }

  Future<void> loadAttendanceRecords(String userId) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _currentPage = 0;
    _hasReachedMax = false;
    notifyListeners();

    final result = await getAttendanceUseCase(userId, page: _currentPage);
    
    result.when(
      success: (data) {
        _records = data;
        _error = null;
        _hasReachedMax = data.length < 20; // Assuming page size is 20
        _currentPage++;
      },
      error: (failure) {
        _error = failure;
      },
    );
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreRecords(String userId) async {
    if (_isLoadingMore || _hasReachedMax || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    final result = await getAttendanceUseCase(userId, page: _currentPage);
    
    result.when(
      success: (data) {
        if (data.isEmpty) {
          _hasReachedMax = true;
        } else {
          _records.addAll(data);
          _currentPage++;
        }
        _error = null;
      },
      error: (failure) {
        _error = failure;
      },
    );
    
    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> checkIn(String userId) async {
    try {
      final result = await checkInUseCase(userId);
      result.fold(
        (failure) => _error = failure,
        (success) {
          loadAttendanceRecords(userId);
          notificationService.showForegroundNotification(
            title: 'Check-in Successful',
            body: 'You have successfully checked in.',
            payload: 'check_in',
          );
        },
      );
    } catch (e) {
      _error = Failure(e.toString());
    }
    notifyListeners();
  }

  Future<void> checkOut(String userId) async {
    try {
      final result = await checkOutUseCase(userId);
      result.fold(
        (failure) => _error = failure,
        (success) {
          loadAttendanceRecords(userId);
          notificationService.showForegroundNotification(
            title: 'Check-out Successful',
            body: 'You have successfully checked out.',
            payload: 'check_out',
          );
        },
      );
    } catch (e) {
      _error = Failure(e.toString());
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}