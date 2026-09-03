import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/entities/location_snapshot.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/monitoring_state.dart';

class EventChannelService {
  static const _monitoringChannel = EventChannel('rainguard/events');
  static const _locationChannel = EventChannel('rainguard/location');

  Stream<MonitoringState>? _monitoringStateStream;
  Stream<LocationSnapshot>? _locationStream;

  StreamSubscription? _monitoringSubscription;
  StreamSubscription? _locationSubscription;

  StreamController<MonitoringState>? _monitoringController;
  StreamController<LocationSnapshot>? _locationController;

  Stream<MonitoringState> get monitoringState {
    _monitoringStateStream ??= _monitoringChannel
        .receiveBroadcastStream()
        .map((event) => MonitoringState.fromMap(Map<String, dynamic>.from(event)))
        .handleError((error) {
      print('Monitoring EventChannel error: $error');
    });
    return _monitoringStateStream!;
  }

  Stream<LocationSnapshot> get locationUpdates {
    _locationStream ??= _locationChannel
        .receiveBroadcastStream()
        .map((event) {
          final data = Map<String, dynamic>.from(event);
          return LocationSnapshot(
            position: GeoPoint(
              latitude: data['latitude'] as double,
              longitude: data['longitude'] as double,
            ),
            accuracy: data['accuracy'] as double,
            speed: data['speed'] as double,
            bearing: data['bearing'] as double,
            timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
          );
        })
        .handleError((error) {
      print('Location EventChannel error: $error');
    });
    return _locationStream!;
  }

  void startListening() {
    _monitoringController = StreamController<MonitoringState>.broadcast();
    _locationController = StreamController<LocationSnapshot>.broadcast();

    _monitoringSubscription = monitoringState.listen(
      (state) => _monitoringController?.add(state),
      onError: (error) => _monitoringController?.addError(error),
    );

    _locationSubscription = locationUpdates.listen(
      (location) => _locationController?.add(location),
      onError: (error) => _locationController?.addError(error),
    );
  }

  void stopListening() {
    _monitoringSubscription?.cancel();
    _monitoringSubscription = null;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _monitoringController?.close();
    _monitoringController = null;
    _locationController?.close();
    _locationController = null;
  }

  void dispose() {
    stopListening();
  }
}
