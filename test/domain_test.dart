import 'package:flutter_test/flutter_test.dart';
import 'package:rain_guard/domain/entities/geo_point.dart';
import 'package:rain_guard/domain/entities/monitoring_state.dart';
import 'package:rain_guard/domain/enums/rain_risk_state.dart';

void main() {
  group('GeoPoint', () {
    test('distanceBetween calculates correct distance', () {
      const point1 = GeoPoint(latitude: 40.7128, longitude: -74.0060); // New York
      const point2 = GeoPoint(latitude: 34.0522, longitude: -118.2437); // Los Angeles

      final distance = GeoPoint.distanceBetween(point1, point2);

      // Distance should be approximately 3944 km
      expect(distance, closeTo(3944000, 50000));
    });

    test('bearingBetween calculates correct bearing', () {
      const point1 = GeoPoint(latitude: 0, longitude: 0);
      const point2 = GeoPoint(latitude: 0, longitude: 1);

      final bearing = GeoPoint.bearingBetween(point1, point2);

      // Bearing should be approximately 90 degrees (east)
      expect(bearing, closeTo(90, 1));
    });
  });

  group('MonitoringState', () {
    test('creates with default values', () {
      const state = MonitoringState();

      expect(state.isMonitoring, false);
      expect(state.riskState, RainRiskState.unknown);
      expect(state.eta, null);
      expect(state.hasLocation, false);
    });

    test('copyWith works correctly', () {
      const state = MonitoringState();
      final newState = state.copyWith(
        isMonitoring: true,
        riskState: RainRiskState.watch,
      );

      expect(newState.isMonitoring, true);
      expect(newState.riskState, RainRiskState.watch);
    });
  });

  group('RainRiskState', () {
    test('displayName returns correct string', () {
      expect(RainRiskState.idle.displayName, 'Sin lluvia cercana');
      expect(RainRiskState.raining.displayName, 'Está lloviendo');
    });

    test('emoji returns correct emoji', () {
      expect(RainRiskState.idle.emoji, '☀️');
      expect(RainRiskState.warning.emoji, '⚠️');
    });
  });
}
