import 'package:flutter_test/flutter_test.dart';
import 'package:rain_guard/domain/entities/geo_point.dart';

void main() {
  group('GeoPoint', () {
    test('creates with correct values', () {
      const point = GeoPoint(latitude: 40.7128, longitude: -74.0060);

      expect(point.latitude, 40.7128);
      expect(point.longitude, -74.0060);
    });

    test('distanceBetween calculates correct distance', () {
      const newYork = GeoPoint(latitude: 40.7128, longitude: -74.0060);
      const losAngeles = GeoPoint(latitude: 34.0522, longitude: -118.2437);

      final distance = GeoPoint.distanceBetween(newYork, losAngeles);

      // Distance should be approximately 3944 km
      expect(distance, closeTo(3944000, 50000));
    });

    test('distanceBetween returns 0 for same point', () {
      const point = GeoPoint(latitude: 40.7128, longitude: -74.0060);

      final distance = GeoPoint.distanceBetween(point, point);

      expect(distance, 0);
    });

    test('bearingBetween calculates correct bearing', () {
      const origin = GeoPoint(latitude: 0, longitude: 0);
      const east = GeoPoint(latitude: 0, longitude: 1);

      final bearing = GeoPoint.bearingBetween(origin, east);

      // Bearing should be approximately 90 degrees (east)
      expect(bearing, closeTo(90, 1));
    });

    test('bearingBetween calculates north bearing', () {
      const origin = GeoPoint(latitude: 0, longitude: 0);
      const north = GeoPoint(latitude: 1, longitude: 0);

      final bearing = GeoPoint.bearingBetween(origin, north);

      // Bearing should be approximately 0 degrees (north)
      expect(bearing, closeTo(0, 1));
    });

    test('projectPoint projects correctly', () {
      const origin = GeoPoint(latitude: 0, longitude: 0);

      // Project 111 km north (approximately 1 degree latitude)
      final projected = GeoPoint.projectPoint(origin, 0, 111000);

      expect(projected.latitude, closeTo(1, 0.1));
      expect(projected.longitude, closeTo(0, 0.1));
    });

    test('toMap and fromMap work correctly', () {
      const original = GeoPoint(latitude: 40.7128, longitude: -74.0060);

      final map = original.toMap();
      final restored = GeoPoint.fromMap(map);

      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
    });

    test('equality works correctly', () {
      const point1 = GeoPoint(latitude: 40.7128, longitude: -74.0060);
      const point2 = GeoPoint(latitude: 40.7128, longitude: -74.0060);
      const point3 = GeoPoint(latitude: 34.0522, longitude: -118.2437);

      expect(point1, point2);
      expect(point1 == point3, false);
    });

    test('hashCode is consistent', () {
      const point1 = GeoPoint(latitude: 40.7128, longitude: -74.0060);
      const point2 = GeoPoint(latitude: 40.7128, longitude: -74.0060);

      expect(point1.hashCode, point2.hashCode);
    });
  });
}
