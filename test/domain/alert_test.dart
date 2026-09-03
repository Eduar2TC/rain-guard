import 'package:flutter_test/flutter_test.dart';
import 'package:rain_guard/domain/entities/rain_arrival_prediction.dart';
import 'package:rain_guard/domain/entities/monitoring_state.dart';
import 'package:rain_guard/domain/enums/rain_risk_state.dart';
import 'package:rain_guard/domain/enums/rain_intensity.dart';
import 'package:rain_guard/domain/enums/prediction_confidence.dart';
import 'package:rain_guard/domain/services/alert_engine.dart';
import 'package:rain_guard/domain/services/hysteresis_manager.dart';
import 'package:rain_guard/domain/services/anti_spam_manager.dart';

void main() {
  group('AlertEngine', () {
    late AlertEngine engine;

    setUp(() {
      engine = AlertEngine();
    });

    test('does not alert when monitoring is paused', () {
      final prediction = RainArrivalPrediction(
        state: RainRiskState.warning,
        eta: const Duration(minutes: 5),
        intensity: RainIntensity.moderate,
        confidence: PredictionConfidence.high,
        source: 'test',
        timestamp: DateTime.now(),
      );

      const currentState = MonitoringState(
        riskState: RainRiskState.idle,
        isPaused: true,
      );

      final decision = engine.evaluate(
        prediction: prediction,
        currentState: currentState,
      );

      expect(decision.shouldNotify, false);
    });

    test('alerts when state changes from idle to warning', () {
      final prediction = RainArrivalPrediction(
        state: RainRiskState.warning,
        eta: const Duration(minutes: 5),
        intensity: RainIntensity.moderate,
        confidence: PredictionConfidence.high,
        source: 'test',
        timestamp: DateTime.now(),
      );

      const currentState = MonitoringState(
        riskState: RainRiskState.idle,
        isPaused: false,
      );

      final decision = engine.evaluate(
        prediction: prediction,
        currentState: currentState,
      );

      expect(decision.shouldNotify, true);
      expect(decision.newState, RainRiskState.warning);
    });

    test('does not alert when state has not changed', () {
      final prediction = RainArrivalPrediction(
        state: RainRiskState.idle,
        eta: null,
        intensity: RainIntensity.none,
        confidence: PredictionConfidence.none,
        source: 'test',
        timestamp: DateTime.now(),
      );

      const currentState = MonitoringState(
        riskState: RainRiskState.idle,
        isPaused: false,
      );

      final decision = engine.evaluate(
        prediction: prediction,
        currentState: currentState,
      );

      expect(decision.shouldNotify, false);
    });

    test('generates correct message for warning state', () {
      final prediction = RainArrivalPrediction(
        state: RainRiskState.warning,
        eta: const Duration(minutes: 5),
        intensity: RainIntensity.moderate,
        confidence: PredictionConfidence.high,
        source: 'test',
        timestamp: DateTime.now(),
      );

      const currentState = MonitoringState(
        riskState: RainRiskState.idle,
        isPaused: false,
      );

      final decision = engine.evaluate(
        prediction: prediction,
        currentState: currentState,
      );

      expect(decision.message, contains('5 min'));
      expect(decision.message, contains('busca refugio'));
    });

    test('generates correct message for imminent state', () {
      final prediction = RainArrivalPrediction(
        state: RainRiskState.imminent,
        eta: const Duration(minutes: 2),
        intensity: RainIntensity.heavy,
        confidence: PredictionConfidence.high,
        source: 'test',
        timestamp: DateTime.now(),
      );

      const currentState = MonitoringState(
        riskState: RainRiskState.idle,
        isPaused: false,
      );

      final decision = engine.evaluate(
        prediction: prediction,
        currentState: currentState,
      );

      expect(decision.message, contains('inminente'));
      expect(decision.message, contains('refúgiate'));
    });

    test('generates correct message for raining state', () {
      final prediction = RainArrivalPrediction(
        state: RainRiskState.raining,
        eta: Duration.zero,
        intensity: RainIntensity.moderate,
        confidence: PredictionConfidence.high,
        source: 'test',
        timestamp: DateTime.now(),
      );

      const currentState = MonitoringState(
        riskState: RainRiskState.idle,
        isPaused: false,
      );

      final decision = engine.evaluate(
        prediction: prediction,
        currentState: currentState,
      );

      expect(decision.message, contains('Está lloviendo'));
    });

    test('reset clears state', () {
      engine.reset();

      final prediction = RainArrivalPrediction(
        state: RainRiskState.warning,
        eta: const Duration(minutes: 5),
        intensity: RainIntensity.moderate,
        confidence: PredictionConfidence.high,
        source: 'test',
        timestamp: DateTime.now(),
      );

      const currentState = MonitoringState(
        riskState: RainRiskState.idle,
        isPaused: false,
      );

      final decision = engine.evaluate(
        prediction: prediction,
        currentState: currentState,
      );

      expect(decision.shouldNotify, true);
    });
  });

  group('HysteresisManager', () {
    late HysteresisManager hysteresis;

    setUp(() {
      hysteresis = HysteresisManager();
    });

    test('allows immediate escalation', () {
      final result = hysteresis.processStateChange(
        currentState: RainRiskState.idle,
        newState: RainRiskState.warning,
      );

      expect(result, RainRiskState.warning);
    });

    test('requires confirmation to enter RAINING', () {
      // First observation
      final result1 = hysteresis.processStateChange(
        currentState: RainRiskState.warning,
        newState: RainRiskState.raining,
      );
      expect(result1, RainRiskState.warning); // Should not change yet

      // Second observation
      final result2 = hysteresis.processStateChange(
        currentState: RainRiskState.warning,
        newState: RainRiskState.raining,
      );
      expect(result2, RainRiskState.raining); // Now it changes
    });

    test('requires multiple observations to leave RAINING', () {
      // Start raining
      hysteresis.processStateChange(
        currentState: RainRiskState.warning,
        newState: RainRiskState.raining,
      );
      hysteresis.processStateChange(
        currentState: RainRiskState.warning,
        newState: RainRiskState.raining,
      );

      // First observation of no rain
      final result1 = hysteresis.processStateChange(
        currentState: RainRiskState.raining,
        newState: RainRiskState.idle,
      );
      expect(result1, RainRiskState.raining); // Should stay raining

      // Second observation
      final result2 = hysteresis.processStateChange(
        currentState: RainRiskState.raining,
        newState: RainRiskState.idle,
      );
      expect(result2, RainRiskState.raining); // Should stay raining

      // Third observation
      final result3 = hysteresis.processStateChange(
        currentState: RainRiskState.raining,
        newState: RainRiskState.idle,
      );
      expect(result3, RainRiskState.idle); // Now it changes
    });

    test('shouldEscalate returns true for more severe states', () {
      expect(hysteresis.shouldEscalate(current: RainRiskState.idle, proposed: RainRiskState.warning), true);
      expect(hysteresis.shouldEscalate(current: RainRiskState.warning, proposed: RainRiskState.idle), false);
    });

    test('reset clears state', () {
      hysteresis.processStateChange(
        currentState: RainRiskState.warning,
        newState: RainRiskState.raining,
      );

      hysteresis.reset();

      // After reset, should allow immediate change
      final result = hysteresis.processStateChange(
        currentState: RainRiskState.warning,
        newState: RainRiskState.raining,
      );
      expect(result, RainRiskState.raining);
    });
  });

  group('AntiSpamManager', () {
    late AntiSpamManager antiSpam;

    setUp(() {
      antiSpam = AntiSpamManager();
    });

    test('allows first alert', () {
      expect(antiSpam.canAlert(RainRiskState.warning), true);
    });

    test('blocks repeated alerts within interval', () {
      antiSpam.recordAlert(RainRiskState.warning);
      expect(antiSpam.canAlert(RainRiskState.warning), false);
    });

    test('tracks last alerted state', () {
      antiSpam.recordAlert(RainRiskState.warning);
      expect(antiSpam.isNewTransition(RainRiskState.warning), false);
      expect(antiSpam.isNewTransition(RainRiskState.imminent), true);
    });

    test('reset clears state', () {
      antiSpam.recordAlert(RainRiskState.warning);
      antiSpam.reset();
      expect(antiSpam.canAlert(RainRiskState.warning), true);
    });
  });
}
