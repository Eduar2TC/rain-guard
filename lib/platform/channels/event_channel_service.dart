import 'package:flutter/services.dart';

import '../../domain/entities/location_snapshot.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/monitoring_state.dart';

class EventChannelService {
  static const _monitoringChannel = EventChannel('rainguard/events');
  static const _locationChannel = EventChannel('rainguard/location');

  Stream<MonitoringState>? _monitoringStateStream;
  Stream<LocationSnapshot>? _locationStream;

  Stream<MonitoringState> get monitoringState {
    _monitoringStateStream ??= _monitoringChannel
        .receiveBroadcastStream()
        .map((event) => MonitoringState.fromMap(Map<String, dynamic>.from(event)))
        .handleError((error) {
      // Stream errors are handled by subscribers
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
              latitude: ((data['latitude'] as num?) ?? 0.0).toDouble(),
              longitude: ((data['longitude'] as num?) ?? 0.0).toDouble(),
            ),
            accuracy: ((data['accuracy'] as num?) ?? 0.0).toDouble(),
            speed: ((data['speed'] as num?) ?? 0.0).toDouble(),
            bearing: ((data['bearing'] as num?) ?? 0.0).toDouble(),
            timestamp: data['timestamp'] != null
                ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int)
                : DateTime.now(),
          );
        })
        .handleError((error) {
      // Stream errors are handled by subscribers
    });
    return _locationStream!;
  }
}
