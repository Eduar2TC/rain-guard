import '../entities/rain_arrival_prediction.dart';
import '../entities/monitoring_state.dart';
import '../entities/alert_decision.dart';
import '../enums/rain_risk_state.dart';
import '../enums/alert_priority.dart';
import 'hysteresis_manager.dart';
import 'anti_spam_manager.dart';

class AlertEngine {
  final HysteresisManager _hysteresis;
  final AntiSpamManager _antiSpam;

  AlertEngine({
    HysteresisManager? hysteresis,
    AntiSpamManager? antiSpam,
  })  : _hysteresis = hysteresis ?? HysteresisManager(),
        _antiSpam = antiSpam ?? AntiSpamManager();

  AlertDecision evaluate({
    required RainArrivalPrediction prediction,
    required MonitoringState currentState,
  }) {
    // If monitoring is paused, don't alert
    if (currentState.isPaused) {
      return AlertDecision.noAlert();
    }

    // Get the proposed new state
    final newState = prediction.state;

    // Check if state actually changed
    if (newState == currentState.riskState) {
      return AlertDecision.noAlert();
    }

    // Apply hysteresis
    final finalState = _hysteresis.processStateChange(
      currentState: currentState.riskState,
      newState: newState,
    );

    // If hysteresis blocked the change, don't alert
    if (finalState == currentState.riskState) {
      return AlertDecision.noAlert();
    }

    // Check anti-spam
    if (!_antiSpam.canAlert(finalState)) {
      return AlertDecision.noAlert();
    }

    // Generate alert decision
    final decision = _generateDecision(
      newState: finalState,
      prediction: prediction,
    );

    // Record the alert for anti-spam
    if (decision.shouldNotify) {
      _antiSpam.recordAlert(finalState);
    }

    return decision;
  }

  AlertDecision _generateDecision({
    required RainRiskState newState,
    required RainArrivalPrediction prediction,
  }) {
    String message;
    AlertPriority priority;
    bool playSound;
    bool vibrate;

    switch (newState) {
      case RainRiskState.idle:
        message = 'Sin lluvia cercana';
        priority = AlertPriority.low;
        playSound = false;
        vibrate = false;
        break;

      case RainRiskState.watch:
        message = '🌦️ Posible lluvia en ~${prediction.etaMinutes ?? "?"} min';
        priority = AlertPriority.low;
        playSound = false;
        vibrate = false;
        break;

      case RainRiskState.approaching:
        message = '🌧️ Lluvia acercándose · ~${prediction.etaMinutes ?? "?"} min';
        priority = AlertPriority.normal;
        playSound = true;
        vibrate = false;
        break;

      case RainRiskState.warning:
        message = '⚠️ Lluvia en ~${prediction.etaMinutes ?? "?"} min · busca refugio';
        priority = AlertPriority.high;
        playSound = true;
        vibrate = true;
        break;

      case RainRiskState.imminent:
        message = '🚨 Lluvia inminente · refúgiate';
        priority = AlertPriority.critical;
        playSound = true;
        vibrate = true;
        break;

      case RainRiskState.raining:
        message = '🌧️ Está lloviendo';
        priority = AlertPriority.high;
        playSound = true;
        vibrate = true;
        break;

      case RainRiskState.passed:
        message = '✓ La lluvia pasó';
        priority = AlertPriority.low;
        playSound = false;
        vibrate = false;
        break;

      case RainRiskState.unknown:
        return AlertDecision.noAlert();
    }

    return AlertDecision(
      shouldNotify: true,
      newState: newState,
      message: message,
      priority: priority,
      playSound: playSound,
      vibrate: vibrate,
    );
  }

  void reset() {
    _hysteresis.reset();
    _antiSpam.reset();
  }
}
