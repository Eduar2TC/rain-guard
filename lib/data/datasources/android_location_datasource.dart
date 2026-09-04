import 'dart:async';

import '../../core/logging/app_logger.dart';
import '../../domain/entities/location_snapshot.dart';
import '../../domain/entities/geo_point.dart';
import '../../platform/channels/method_channel_service.dart';
import '../../platform/channels/event_channel_service.dart';

class AndroidLocationDataSource {
  final MethodChannelService _methodChannel;
  final EventChannelService _eventChannel;

  StreamController<LocationSnapshot>? _locationController;
  StreamSubscription? _locationSubscription;

  AndroidLocationDataSource({
    required MethodChannelService methodChannel,
    required EventChannelService eventChannel,
  })  : _methodChannel = methodChannel,
        _eventChannel = eventChannel;

  Stream<LocationSnapshot> get locationStream {
    _locationController ??= StreamController<LocationSnapshot>.broadcast();
    return _locationController!.stream;
  }

  Future<void> startUpdates() async {
    await _methodChannel.startLocationUpdates();
    _listenToLocationEvents();
  }

  Future<void> stopUpdates() async {
    await _methodChannel.stopLocationUpdates();
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  void _listenToLocationEvents() {
    _locationSubscription?.cancel();
    _locationSubscription = _eventChannel.locationUpdates.listen(
      (locationData) {
        _locationController?.add(locationData);
      },
      onError: (error) {
        logger.warning(LogTags.location, 'Location stream error: $error');
      },
    );
  }

  Future<LocationSnapshot?> getLastKnownLocation() async {
    final data = await _methodChannel.getLastKnownLocation();
    if (data == null) return null;

    final lat = (data['latitude'] as num?)?.toDouble();
    final lon = (data['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    return LocationSnapshot(
      position: GeoPoint(
        latitude: lat,
        longitude: lon,
      ),
      accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0.0,
      speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
      bearing: (data['bearing'] as num?)?.toDouble() ?? 0.0,
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int)
          : DateTime.now(),
    );
  }

  Future<bool> hasPermission() async {
    return _methodChannel.hasLocationPermission();
  }

  Future<bool> requestPermission() async {
    return _methodChannel.requestLocationPermission();
  }

  Future<bool> requestBackgroundPermission() async {
    return _methodChannel.requestBackgroundLocationPermission();
  }

  void dispose() {
    _locationSubscription?.cancel();
    _locationController?.close();
  }
}
