import 'package:flutter_test/flutter_test.dart';
import 'package:rain_guard/domain/entities/geo_point.dart';
import 'package:rain_guard/domain/entities/location_snapshot.dart';
import 'package:rain_guard/domain/enums/movement_state.dart';

void main() {
  group('LocationSnapshot', () {
    test('creates with correct values', () {
      final location = LocationSnapshot(
        position: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
        accuracy: 10.0,
        speed: 5.0,
        bearing: 90.0,
        timestamp: DateTime.now(),
      );

      expect(location.position.latitude, 40.7128);
      expect(location.position.longitude, -74.0060);
      expect(location.accuracy, 10.0);
      expect(location.speed, 5.0);
      expect(location.bearing, 90.0);
    });

    test('speedKmh converts correctly', () {
      final location = LocationSnapshot(
        position: const GeoPoint(latitude: 0, longitude: 0),
        accuracy: 10.0,
        speed: 5.0, // 5 m/s = 18 km/h
        bearing: 0,
        timestamp: DateTime.now(),
      );

      expect(location.speedKmh, 18.0);
    });

    test('movementState returns correct state', () {
      // Stopped
      final stopped = LocationSnapshot(
        position: const GeoPoint(latitude: 0, longitude: 0),
        accuracy: 10.0,
        speed: 0.2, // < 1 km/h (0.72 km/h)
        bearing: 0,
        timestamp: DateTime.now(),
      );
      expect(stopped.movementState, MovementState.stopped);

      // Slow
      final slow = LocationSnapshot(
        position: const GeoPoint(latitude: 0, longitude: 0),
        accuracy: 10.0,
        speed: 2.0, // ~7.2 km/h
        bearing: 0,
        timestamp: DateTime.now(),
      );
      expect(slow.movementState, MovementState.slow);

      // Cycling
      final cycling = LocationSnapshot(
        position: const GeoPoint(latitude: 0, longitude: 0),
        accuracy: 10.0,
        speed: 8.0, // ~28.8 km/h
        bearing: 0,
        timestamp: DateTime.now(),
      );
      expect(cycling.movementState, MovementState.cycling);

      // Fast
      final fast = LocationSnapshot(
        position: const GeoPoint(latitude: 0, longitude: 0),
        accuracy: 10.0,
        speed: 10.0, // 36 km/h
        bearing: 0,
        timestamp: DateTime.now(),
      );
      expect(fast.movementState, MovementState.fast);
    });

    test('isAccurate returns true for accuracy < 100', () {
      final accurate = LocationSnapshot(
        position: const GeoPoint(latitude: 0, longitude: 0),
        accuracy: 50.0,
        speed: 0,
        bearing: 0,
        timestamp: DateTime.now(),
      );
      expect(accurate.isAccurate, true);

      final inaccurate = LocationSnapshot(
        position: const GeoPoint(latitude: 0, longitude: 0),
        accuracy: 150.0,
        speed: 0,
        bearing: 0,
        timestamp: DateTime.now(),
      );
      expect(inaccurate.isAccurate, false);
    });

    test('copyWith works correctly', () {
      final original = LocationSnapshot(
        position: const GeoPoint(latitude: 0, longitude: 0),
        accuracy: 10.0,
        speed: 5.0,
        bearing: 90.0,
        timestamp: DateTime.now(),
      );

      final modified = original.copyWith(
        speed: 10.0,
        bearing: 180.0,
      );

      expect(modified.speed, 10.0);
      expect(modified.bearing, 180.0);
      expect(modified.accuracy, 10.0); // Unchanged
    });

    test('toMap and fromMap work correctly', () {
      final original = LocationSnapshot(
        position: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
        accuracy: 10.0,
        speed: 5.0,
        bearing: 90.0,
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final map = original.toMap();
      final restored = LocationSnapshot.fromMap(map);

      expect(restored.position.latitude, original.position.latitude);
      expect(restored.position.longitude, original.position.longitude);
      expect(restored.accuracy, original.accuracy);
      expect(restored.speed, original.speed);
      expect(restored.bearing, original.bearing);
    });
  });
}
