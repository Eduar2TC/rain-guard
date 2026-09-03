import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkType { wifi, mobile, noConnection }

class NetworkDataSource {
  final Connectivity _connectivity;
  StreamSubscription<ConnectivityResult>? _subscription;
  final StreamController<NetworkType> _controller = StreamController<NetworkType>.broadcast();

  NetworkDataSource({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  Stream<NetworkType> get networkTypeStream => _controller.stream;

  NetworkType _currentType = NetworkType.noConnection;
  NetworkType get currentType => _currentType;

  bool get isConnected => _currentType != NetworkType.noConnection;

  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _currentType = _mapConnectivityResult(result);
    _controller.add(_currentType);

    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _currentType = _mapConnectivityResult(result);
      _controller.add(_currentType);
    });
  }

  NetworkType _mapConnectivityResult(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        return NetworkType.wifi;
      case ConnectivityResult.mobile:
        return NetworkType.mobile;
      case ConnectivityResult.ethernet:
        return NetworkType.wifi;
      case ConnectivityResult.bluetooth:
        return NetworkType.mobile;
      case ConnectivityResult.vpn:
        return NetworkType.mobile;
      case ConnectivityResult.other:
        return NetworkType.mobile;
      case ConnectivityResult.none:
        return NetworkType.noConnection;
    }
  }

  Future<bool> hasInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('api.open-meteo.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
