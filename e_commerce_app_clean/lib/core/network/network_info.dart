import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker? internetConnectionChecker;

  NetworkInfoImpl({this.internetConnectionChecker});
  @override
  Future<bool> get isConnected {
    if (kIsWeb) {
      return Future.value(true);
    }
    return internetConnectionChecker?.hasConnection ?? Future.value(true);
  }
}

class WebNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected => Future.value(true);
}
