import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/location_snapshot.dart';
import 'providers.dart';

// Location State
class LocationState {
  final LocationSnapshot? currentLocation;
  final bool isLoading;
  final String? error;
  final bool hasPermission;
  final bool hasBackgroundPermission;

  const LocationState({
    this.currentLocation,
    this.isLoading = false,
    this.error,
    this.hasPermission = false,
    this.hasBackgroundPermission = false,
  });

  bool get hasLocation => currentLocation != null;

  LocationState copyWith({
    LocationSnapshot? currentLocation,
    bool? isLoading,
    String? error,
    bool? hasPermission,
    bool? hasBackgroundPermission,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasPermission: hasPermission ?? this.hasPermission,
      hasBackgroundPermission: hasBackgroundPermission ?? this.hasBackgroundPermission,
    );
  }
}

// Location State Notifier
class LocationStateNotifier extends StateNotifier<LocationState> {
  final AndroidLocationDataSource _dataSource;
  StreamSubscription? _locationSubscription;

  LocationStateNotifier(this._dataSource) : super(const LocationState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);

    final hasPermission = await _dataSource.hasPermission();
    final hasBackgroundPermission = await _dataSource.requestBackgroundPermission();

    state = state.copyWith(
      isLoading: false,
      hasPermission: hasPermission,
      hasBackgroundPermission: hasBackgroundPermission,
    );
  }

  Future<void> requestPermission() async {
    state = state.copyWith(isLoading: true);
    final granted = await _dataSource.requestPermission();
    state = state.copyWith(
      isLoading: false,
      hasPermission: granted,
    );
  }

  Future<void> startUpdates() async {
    if (!state.hasPermission) {
      await requestPermission();
    }

    if (!state.hasPermission) return;

    await _dataSource.startUpdates();
    _locationSubscription = _dataSource.locationStream.listen(
      (location) {
        state = state.copyWith(currentLocation: location);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  Future<void> stopUpdates() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await _dataSource.stopUpdates();
  }

  void updateLocation(LocationSnapshot location) {
    state = state.copyWith(currentLocation: location);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}

// Provider
final locationStateProvider = StateNotifierProvider<LocationStateNotifier, LocationState>((ref) {
  final dataSource = ref.watch(androidLocationDataSourceProvider);
  return LocationStateNotifier(dataSource);
});
