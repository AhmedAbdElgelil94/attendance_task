import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}

// Add a mock implementation for testing or offline mode
class AlwaysConnectedNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected => Future.value(true);
} 