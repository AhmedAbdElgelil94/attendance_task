import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;

  AuthBloc(this._authService) : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthEvent>(_onCheckAuth);
    on<BiometricLoginEvent>(_onBiometricLogin);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      final user = await _authService.login(event.username, event.password);
      
      // Store user data in SharedPreferences
      await _authService.prefs.setString('user_id', user.id);
      await _authService.prefs.setString('username', user.username);
      
      emit(Authenticated(
        userId: user.id,
        username: user.username,
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      final user = await _authService.register(event.username, event.password);
      
      // Store user data in SharedPreferences
      await _authService.prefs.setString('user_id', user.id);
      await _authService.prefs.setString('username', user.username);
      
      emit(Authenticated(
        userId: user.id,
        username: user.username,
      ));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    try {
      await _authService.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCheckAuth(CheckAuthEvent event, Emitter<AuthState> emit) async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        final userId = await _authService.getCurrentUserId();
        final username = await _authService.getUsername();
        
        if (userId != null && username != null) {
          emit(Authenticated(
            userId: userId,
            username: username,
          ));
          return;
        }
      }
      
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onBiometricLogin(
    BiometricLoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final canCheckBiometrics = await _authService.checkBiometrics();
      if (canCheckBiometrics) {
        final success = await _authService.authenticateWithBiometrics();
        if (success) {
          final userId = await _authService.getCurrentUserId();
          final username = await _authService.getUsername();
          if (userId != null && username != null) {
            emit(Authenticated(userId: userId, username: username));
            return;
          }
        }
      }
      emit(const AuthError('Biometric authentication failed'));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<bool> canUseBiometrics() async {
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (!isLoggedIn) return false;
      return await _authService.checkBiometrics();
    } catch (e) {
      return false;
    }
  }
} 