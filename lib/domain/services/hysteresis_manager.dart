import 'package:rain_guard/domain/enums/rain_risk_state.dart';
import 'package:rain_guard/core/constants/alert_thresholds.dart';

class HysteresisManager {
  // Track consecutive observations for hysteresis
  int _consecutiveRainObservations = 0;
  int _consecutiveNoRainObservations = 0;


  HysteresisManager();

  /// Process a state change with hysteresis
  /// Returns the final state after applying hysteresis rules
  RainRiskState processStateChange({
    required RainRiskState currentState,
    required RainRiskState newState,
  }) {
    // If transitioning TO raining state, require confirmation
    if (newState == RainRiskState.raining) {
      _consecutiveRainObservations++;
      _consecutiveNoRainObservations = 0;

      // Require multiple confirmations to enter RAINING
      if (_consecutiveRainObservations < AlertThresholds.rainConfirmationCycles) {
        // Don't change state yet, wait for more confirmations
        return currentState;
      }

      return RainRiskState.raining;
    }

    // If transitioning FROM raining state, require multiple observations
    if (currentState == RainRiskState.raining && newState != RainRiskState.raining) {
      _consecutiveNoRainObservations++;
      _consecutiveRainObservations = 0;

      // Require multiple confirmations to leave RAINING
      if (_consecutiveNoRainObservations < AlertThresholds.rainPassCycles) {
        // Don't change state yet, stay in RAINING
        return RainRiskState.raining;
      }

      return newState;
    }

    // For other transitions, allow immediately
    _consecutiveRainObservations = 0;
    _consecutiveNoRainObservations = 0;
    return newState;
  }

  /// Check if we should transition to a more severe state
  bool shouldEscalate({
    required RainRiskState current,
    required RainRiskState proposed,
  }) {
    return _severityIndex(proposed) > _severityIndex(current);
  }

  /// Check if we should transition to a less severe state
  bool shouldDeescalate({
    required RainRiskState current,
    required RainRiskState proposed,
  }) {
    return _severityIndex(proposed) < _severityIndex(current);
  }

  int _severityIndex(RainRiskState state) {
    switch (state) {
      case RainRiskState.idle:
        return 0;
      case RainRiskState.watch:
        return 1;
      case RainRiskState.approaching:
        return 2;
      case RainRiskState.warning:
        return 3;
      case RainRiskState.imminent:
        return 4;
      case RainRiskState.raining:
        return 5;
      case RainRiskState.passed:
        return 1;
      case RainRiskState.unknown:
        return -1;
    }
  }

  void reset() {
    _consecutiveRainObservations = 0;
    _consecutiveNoRainObservations = 0;
  }
}
