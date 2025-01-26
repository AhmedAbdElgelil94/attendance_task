import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../data/database_helper.dart';
import '../models/user.dart';

class AuthService {
  final DatabaseHelper _databaseHelper;
  final SharedPreferences prefs;
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  AuthService(
    this._databaseHelper,
    this.prefs,
    this._secureStorage,
    this._localAuth,
  );

  Future<void> saveUserSession(User user) async {
    await prefs.setString('user_id', user.id);
    await prefs.setString('username', user.username);
  }

  Future<User> login(String username, String password) async {
    final user = await _databaseHelper.getUser(username);
    
    if (user == null) {
      throw Exception('User not found');
    }
    
    if (user.password != password) {
      throw Exception('Invalid password');
    }
    
    await saveUserSession(user);
    return user;
  }

  Future<User> register(String username, String password) async {
    final existingUser = await _databaseHelper.getUser(username);
    if (existingUser != null) {
      throw Exception('Username already exists');
    }

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      password: password,
    );

    await _databaseHelper.insertUser(user);
    await saveUserSession(user);
    return user;
  }

  Future<bool> checkBiometrics() async {
    final canCheckBiometrics = await _localAuth.canCheckBiometrics;
    return canCheckBiometrics;
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await prefs.clear();
    await _secureStorage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    return prefs.containsKey('user_id');
  }

  Future<String?> getCurrentUserId() async {
    return prefs.getString('user_id');
  }

  Future<String?> getUsername() async {
    return prefs.getString('username');
  }
} 