import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/attendance/attendance_bloc.dart';
import 'blocs/attendance/attendance_state.dart';
import 'package:get_it/get_it.dart';
import 'services/notification_service.dart';
import 'blocs/auth/auth_event.dart';
import 'services/auth_service.dart';
import 'services/biometric_service.dart';
import 'data/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'config/theme.dart';

Future<void> setupDependencies() async {
  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  final localAuth = LocalAuthentication();
  const secureStorage = FlutterSecureStorage();
  
  // Register core services
  GetIt.I.registerSingleton<SharedPreferences>(prefs);
  GetIt.I.registerSingleton<LocalAuthentication>(localAuth);
  GetIt.I.registerSingleton<FlutterSecureStorage>(secureStorage);
  GetIt.I.registerSingleton<DatabaseHelper>(DatabaseHelper());
  GetIt.I.registerSingleton<BiometricService>(BiometricService(localAuth));
  
  // Initialize and register notification service
  final notificationService = NotificationService(prefs);
  await notificationService.initialize();
  GetIt.I.registerSingleton<NotificationService>(notificationService);
  
  // Register AuthService with its dependencies
  GetIt.I.registerSingleton<AuthService>(
    AuthService(
      GetIt.I<DatabaseHelper>(),
      GetIt.I<SharedPreferences>(),
      GetIt.I<FlutterSecureStorage>(),
      GetIt.I<LocalAuthentication>(),
    ),
  );

  // Register blocs with their dependencies
  GetIt.I.registerSingleton<AuthBloc>(AuthBloc(GetIt.I<AuthService>()));
  GetIt.I.registerSingleton<AttendanceBloc>(
    AttendanceBloc(
      GetIt.I<DatabaseHelper>(),
      GetIt.I<BiometricService>(),
      GetIt.I<SharedPreferences>(),
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup dependencies (including notification initialization)
  await setupDependencies();

  // Initialize auth state
  final authBloc = GetIt.I<AuthBloc>();
  authBloc.add(CheckAuthEvent());
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: GetIt.I<AuthBloc>()),
        BlocProvider<AttendanceBloc>.value(value: GetIt.I<AttendanceBloc>()),
      ],
      child: MaterialApp(
        title: 'Attendance App',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
      ),
    );
  }
}
