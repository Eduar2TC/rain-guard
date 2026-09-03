import '../entities/location_snapshot.dart';

class LocationState {
  final LocationSnapshot? currentLocation;
  final bool isLoading;
  final String? error;
  final bool hasPermission;
  final bool hasBackgroundPermission;
  final DateTime? lastUpdate;

  const LocationState({
    this.currentLocation,
    this.isLoading = false,
    this.error,
    this.hasPermission = false,
    this.hasBackgroundPermission = false,
    this.lastUpdate,
  });

  bool get hasLocation => currentLocation != null;

  bool get isAccurate {
    if (currentLocation == null) return false;
    return currentLocation!.accuracy < 100;
  }

  LocationState copyWith({
    LocationSnapshot? currentLocation,
    bool? isLoading,
    String? error,
    bool? hasPermission,
    bool? hasBackgroundPermission,
    DateTime? lastUpdate,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasPermission: hasPermission ?? this.hasPermission,
      hasBackgroundPermission: hasBackgroundPermission ?? this.hasBackgroundPermission,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  Map<String, dynamic> toMap() => {
        'hasLocation': hasLocation,
        'isLoading': isLoading,
        'error': error,
        'hasPermission': hasPermission,
        'hasBackgroundPermission': hasBackgroundPermission,
        'latitude': currentLocation?.position.latitude,
        'longitude': currentLocation?.position.longitude,
        'accuracy': currentLocation?.accuracy,
        'speed': currentLocation?.speed,
        'bearing': currentLocation?.bearing,
        'lastUpdate': lastUpdate?.toIso8601String(),
      };
}
