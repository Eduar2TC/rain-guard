import '../enums/movement_state.dart';
import 'geo_point.dart';

class LocationSnapshot {
  final GeoPoint position;
  final double accuracy;
  final double speed;
  final double bearing;
  final DateTime timestamp;

  const LocationSnapshot({
    required this.position,
    required this.accuracy,
    required this.speed,
    required this.bearing,
    required this.timestamp,
  });

  MovementState get movementState {
    final speedKmh = speed * 3.6;
    return MovementState.fromSpeedKmh(speedKmh);
  }

  double get speedKmh => speed * 3.6;

  bool get isAccurate => accuracy < 100;

  LocationSnapshot copyWith({
    GeoPoint? position,
    double? accuracy,
    double? speed,
    double? bearing,
    DateTime? timestamp,
  }) {
    return LocationSnapshot(
      position: position ?? this.position,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
        'position': position.toMap(),
        'accuracy': accuracy,
        'speed': speed,
        'bearing': bearing,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LocationSnapshot.fromMap(Map<String, dynamic> map) =>
      LocationSnapshot(
        position: GeoPoint.fromMap(map['position']),
        accuracy: (map['accuracy'] as num).toDouble(),
        speed: (map['speed'] as num).toDouble(),
        bearing: (map['bearing'] as num).toDouble(),
        timestamp: DateTime.parse(map['timestamp']),
      );

  @override
  String toString() =>
      'LocationSnapshot(pos: $position, acc: ${accuracy.toStringAsFixed(1)}m, '
      'speed: ${speedKmh.toStringAsFixed(1)}km/h, bearing: ${bearing.toStringAsFixed(1)}°)';
}
