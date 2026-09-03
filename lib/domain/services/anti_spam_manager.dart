import '../../enums/rain_risk_state.dart';

class AntiSpamManager {
  // Track last alert time for each state
  final Map<RainRiskState, DateTime> _lastAlertTimes = {};

  // Minimum time between alerts for the same state
  static const _minInterval = Duration(minutes: 5);

  // Track if we've already alerted for a transition
  RainRiskState? _lastAlertedState;

  AntiSpamManager();

  /// Check if we can send an alert for this state
  bool canAlert(RainRiskState state) {
    final lastAlertTime = _lastAlertTimes[state];

    if (lastAlertTime == null) {
      return true;
    }

    final timeSinceLastAlert = DateTime.now().difference(lastAlertTime);
    return timeSinceLastAlert >= _minInterval;
  }

  /// Record that we sent an alert for this state
  void recordAlert(RainRiskState state) {
    _lastAlertTimes[state] = DateTime.now();
    _lastAlertedState = state;
  }

  /// Check if this is a new transition (not just a repeat)
  bool isNewTransition(RainRiskState newState) {
    return newState != _lastAlertedState;
  }

  /// Get time until next allowed alert for a state
  Duration? timeUntilNextAlert(RainRiskState state) {
    final lastAlertTime = _lastAlertTimes[state];
    if (lastAlertTime == null) return null;

    final nextAlertTime = lastAlertTime.add(_minInterval);
    final now = DateTime.now();

    if (now.isAfter(nextAlertTime)) {
      return Duration.zero;
    }

    return nextAlertTime.difference(now);
  }

  void reset() {
    _lastAlertTimes.clear();
    _lastAlertedState = null;
  }
}
