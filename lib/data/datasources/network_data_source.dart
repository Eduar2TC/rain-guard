import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkType { wifi, mobile, noConnection }

class NetworkDataSource {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final StreamController<NetworkType> _controller = StreamController<NetworkType>.broadcast();

  NetworkDataSource({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  Stream<NetworkType> get networkTypeStream => _controller.stream;

  NetworkType _currentType = NetworkType.noConnection;
  NetworkType get currentType => _currentType;

  bool get isConnected => _currentType != NetworkType.noConnection;

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _currentType = _mapConnectivityResult(results);
    _controller.add(_currentType);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _currentType = _mapConnectivityResult(results);
      _controller.add(_currentType);
    });
  }

  NetworkType _mapConnectivityResult(List<ConnectivityResult> results) {
    if (results.isEmpty) return NetworkType.noConnection;

    // Prioritize the most capable connection type present.
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.none:
          continue;
        case ConnectivityResult.wifi:
        case ConnectivityResult.ethernet:
          return NetworkType.wifi;
        case ConnectivityResult.mobile:
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.vpn:
        case ConnectivityResult.satellite:
          return NetworkType.mobile;
        case ConnectivityResult.other:
          return NetworkType.mobile;
      }
    }
    return NetworkType.noConnection;
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
