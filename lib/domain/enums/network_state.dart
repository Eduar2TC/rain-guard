enum NetworkState {
  wifi,
  mobile,
  noConnection;

  bool get isConnected => this != NetworkState.noConnection;

  String get displayName {
    switch (this) {
      case NetworkState.wifi:
        return 'WiFi';
      case NetworkState.mobile:
        return 'Datos móviles';
      case NetworkState.noConnection:
        return 'Sin conexión';
    }
  }
}
