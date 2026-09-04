import 'dart:async';

import 'package:rain_guard/core/logging/app_logger.dart';
import 'package:rain_guard/domain/entities/location_snapshot.dart';
import 'package:rain_guard/domain/entities/geo_point.dart';
import 'package:rain_guard/domain/enums/movement_state.dart';
import 'package:rain_guard/platform/channels/method_channel_service.dart';
import 'package:rain_guard/platform/channels/event_channel_service.dart';

class LocationService {
  final MethodChannelService _methodChannel;
  final EventChannelService _eventChannel;

  StreamSubscription? _locationSubscription;
  final StreamController<LocationSnapshot> _locationController =
      StreamController<LocationSnapshot>.broadcast();

  LocationSnapshot? _lastLocation;
  bool _isUpdating = false;

  LocationService({
    required MethodChannelService methodChannel,
    required EventChannelService eventChannel,
  })  : _methodChannel = methodChannel,
        _eventChannel = eventChannel;

  Stream<LocationSnapshot> get locationStream => _locationController.stream;

  LocationSnapshot? get lastLocation => _lastLocation;

  bool get isUpdating => _isUpdating;

  Future<bool> hasPermission() async {
    return _methodChannel.hasLocationPermission();
  }

  Future<bool> requestPermission() async {
    return _methodChannel.requestLocationPermission();
  }

  Future<bool> requestBackgroundPermission() async {
    return _methodChannel.requestBackgroundLocationPermission();
  }

  Future<void> startUpdates() async {
    if (_isUpdating) return;

    final hasPermission = await this.hasPermission();
    if (!hasPermission) {
      final granted = await requestPermission();
      if (!granted) return;
    }

    await _methodChannel.startLocationUpdates();
    _isUpdating = true;

    _locationSubscription?.cancel();
    _locationSubscription = _eventChannel.locationUpdates.listen(
      (location) {
        _lastLocation = location;
        _locationController.add(location);
      },
      onError: (error) {
        logger.warning(LogTags.location, 'Location updates error: $error');
      },
    );
  }

  Future<void> stopUpdates() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await _methodChannel.stopLocationUpdates();
    _isUpdating = false;
  }

  Future<LocationSnapshot?> getLastKnownLocation() async {
    return _lastLocation;
  }

  /// Calculate distance to a point from current location
  double? distanceTo(GeoPoint point) {
    if (_lastLocation == null) return null;
    return GeoPoint.distanceBetween(_lastLocation!.position, point);
  }

  /// Calculate bearing to a point from current location
  double? bearingTo(GeoPoint point) {
    if (_lastLocation == null) return null;
    return GeoPoint.bearingBetween(_lastLocation!.position, point);
  }

  /// Get current movement state
  MovementState get movementState {
    if (_lastLocation == null) return MovementState.stopped;
    return _lastLocation!.movementState;
  }

  /// Get current speed in km/h
  double get speedKmh {
    if (_lastLocation == null) return 0;
    return _lastLocation!.speedKmh;
  }

  void dispose() {
    _locationSubscription?.cancel();
    _locationController.close();
  }
}
