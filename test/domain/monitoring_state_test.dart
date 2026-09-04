import 'package:flutter_test/flutter_test.dart';
import 'package:rain_guard/domain/entities/monitoring_state.dart';
import 'package:rain_guard/domain/enums/rain_risk_state.dart';
import 'package:rain_guard/domain/enums/prediction_confidence.dart';
import 'package:rain_guard/domain/enums/rain_intensity.dart';
import 'package:rain_guard/domain/enums/monitoring_mode.dart';

void main() {
  group('MonitoringState', () {
    test('creates with default values', () {
      const state = MonitoringState();

      expect(state.isMonitoring, false);
      expect(state.riskState, RainRiskState.unknown);
      expect(state.eta, null);
      expect(state.confidence, PredictionConfidence.none);
      expect(state.rainIntensity, RainIntensity.none);
      expect(state.hasLocation, false);
      expect(state.isDataStale, true);
    });

    test('hasLocation returns true when location is set', () {
      const state = MonitoringState(
        latitude: 40.7128,
        longitude: -74.0060,
      );

      expect(state.hasLocation, true);
    });

    test('isDataStale returns true when data is old', () {
      const state = MonitoringState(
        dataAge: Duration(minutes: 15),
      );

      expect(state.isDataStale, true);
    });

    test('isDataStale returns false when data is fresh', () {
      const state = MonitoringState(
        dataAge: Duration(minutes: 5),
      );

      expect(state.isDataStale, false);
    });

    test('etaMinutes returns correct value', () {
      const state = MonitoringState(
        eta: Duration(minutes: 5),
      );

      expect(state.etaMinutes, 5);
    });

    test('etaMinutes returns null when eta is null', () {
      const state = MonitoringState();

      expect(state.etaMinutes, null);
    });

    test('copyWith works correctly', () {
      const original = MonitoringState();
      final modified = original.copyWith(
        isMonitoring: true,
        riskState: RainRiskState.warning,
        eta: const Duration(minutes: 5),
      );

      expect(modified.isMonitoring, true);
      expect(modified.riskState, RainRiskState.warning);
      expect(modified.eta?.inMinutes, 5);
      expect(modified.confidence, PredictionConfidence.none); // Unchanged
    });

    test('toMap and fromMap work correctly', () {
      const original = MonitoringState(
        isMonitoring: true,
        riskState: RainRiskState.warning,
        eta: Duration(minutes: 5),
        confidence: PredictionConfidence.high,
        rainIntensity: RainIntensity.moderate,
        latitude: 40.7128,
        longitude: -74.0060,
        speed: 5.0,
        bearing: 90.0,
        batteryLevel: 75,
        bubbleVisible: true,
        monitoringMode: MonitoringMode.full,
      );

      final map = original.toMap();
      final restored = MonitoringState.fromMap(map);

      expect(restored.isMonitoring, original.isMonitoring);
      expect(restored.riskState, original.riskState);
      expect(restored.eta?.inMinutes, original.eta?.inMinutes);
      expect(restored.confidence, original.confidence);
      expect(restored.rainIntensity, original.rainIntensity);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
    });
  });

  group('Enums', () {
    test('RainRiskState has correct display names', () {
      expect(RainRiskState.idle.displayName, 'Sin lluvia cercana');
      expect(RainRiskState.watch.displayName, 'Posible lluvia');
      expect(RainRiskState.approaching.displayName, 'Lluvia acercándose');
      expect(RainRiskState.warning.displayName, 'Prepárate');
      expect(RainRiskState.imminent.displayName, 'Lluvia inminente');
      expect(RainRiskState.raining.displayName, 'Está lloviendo');
      expect(RainRiskState.passed.displayName, 'Lluvia pasó');
      expect(RainRiskState.unknown.displayName, 'Sin datos');
    });

    test('RainRiskState has correct emojis', () {
      expect(RainRiskState.idle.emoji, '☀️');
      expect(RainRiskState.watch.emoji, '🌦️');
      expect(RainRiskState.approaching.emoji, '🌧️');
      expect(RainRiskState.warning.emoji, '⚠️');
      expect(RainRiskState.imminent.emoji, '🚨');
      expect(RainRiskState.raining.emoji, '🌧️');
      expect(RainRiskState.passed.emoji, '✓');
      expect(RainRiskState.unknown.emoji, '?');
    });

    test('RainIntensity fromMmPerHour works correctly', () {
      expect(RainIntensity.fromMmPerHour(0).name, 'none');
      expect(RainIntensity.fromMmPerHour(0.3).name, 'none');
      expect(RainIntensity.fromMmPerHour(1.0).name, 'light');
      expect(RainIntensity.fromMmPerHour(5.0).name, 'moderate');
      expect(RainIntensity.fromMmPerHour(15.0).name, 'heavy');
      expect(RainIntensity.fromMmPerHour(35.0).name, 'extreme');
    });

    test('PredictionConfidence fromScore works correctly', () {
      expect(PredictionConfidence.fromScore(0.1).name, 'none');
      expect(PredictionConfidence.fromScore(0.5).name, 'low');
      expect(PredictionConfidence.fromScore(0.7).name, 'medium');
      expect(PredictionConfidence.fromScore(0.9).name, 'high');
    });
  });
}
