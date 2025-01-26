import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/database_helper.dart';
import '../data/network/network_info.dart';
import '../services/auth_service.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/attendance/attendance_bloc.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';
import '../domain/repositories/attendance_repository.dart';
import '../data/repositories/attendance_repository_impl.dart';
import '../domain/usecases/get_attendance.dart';
import '../domain/usecases/check_in.dart';
import '../domain/usecases/check_out.dart';
import '../presentation/viewmodels/attendance_viewmodel.dart';
import '../data/datasources/attendance_hive_datasource.dart';

final GetIt locator = GetIt.instance;

Future<void> setupDependencies() async {
  // Core
  try {
    final internetChecker = InternetConnectionChecker();
    locator.registerLazySingleton(() => internetChecker);
    locator.registerLazySingleton<NetworkInfo>(
      () => NetworkInfoImpl(locator()),
    );
  } catch (e) {
    // Fallback to always connected for offline mode or testing
    locator.registerLazySingleton<NetworkInfo>(
      () => AlwaysConnectedNetworkInfo(),
    );
  }

  // Connectivity
  locator.registerLazySingleton(() => Connectivity());

  // Database
  locator.registerLazySingleton(() => DatabaseHelper());

  // Hive
  final hiveDataSource = await AttendanceHiveDataSource.init();
  locator.registerSingleton(hiveDataSource);

  // Cache
  final sharedPreferences = await SharedPreferences.getInstance();
  locator.registerSingleton(sharedPreferences);

  // Repositories
  locator.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(
      hiveDataSource: locator(),
      cache: locator(),
      networkInfo: locator(),
      connectivity: locator(),
    ),
  );

  // Use Cases
  locator.registerLazySingleton(() => GetAttendanceUseCase(locator()));
  locator.registerLazySingleton(() => CheckInUseCase(locator()));
  locator.registerLazySingleton(() => CheckOutUseCase(locator()));

  // ViewModels
  locator.registerFactory(
    () => AttendanceViewModel(
      getAttendanceUseCase: locator(),
      checkInUseCase: locator(),
      checkOutUseCase: locator(),
      connectivity: locator(),
    ),
  );

  // Services
  locator.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  
  locator.registerLazySingleton<LocalAuthentication>(
    () => LocalAuthentication(),
  );

  // Auth Service
  locator.registerLazySingleton<AuthService>(
    () => AuthService(
      locator<DatabaseHelper>(),
      locator(),
      locator<FlutterSecureStorage>(),
      locator<LocalAuthentication>(),
    ),
  );

  // Blocs
  locator.registerFactory<AuthBloc>(
    () => AuthBloc(locator<AuthService>()),
  );
  
  locator.registerFactory<AttendanceBloc>(
    () => AttendanceBloc(
      locator<DatabaseHelper>(),
      locator<BiometricService>(),
      locator(),
    ),
  );

  // Add BiometricService registration
  locator.registerLazySingleton<BiometricService>(
    () => BiometricService(locator<LocalAuthentication>()),
  );

  // Register NotificationService
  locator.registerLazySingleton<NotificationService>(
    () => NotificationService(locator()),
  );
} 