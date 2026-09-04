import 'dart:async';

import '../enums/rain_risk_state.dart';
import '../../core/constants/alert_thresholds.dart';

class MonitoringScheduler {
  Timer? _timer;
  RainRiskState _currentState = RainRiskState.idle;
  double _batteryLevel = 100;
  bool _isNetworkAvailable = true;

  final Function() _onUpdate;

  MonitoringScheduler({required Function() onUpdate}) : _onUpdate = onUpdate;

  Duration get currentInterval => _calculateInterval();

  void update({
    required RainRiskState riskState,
    double? batteryLevel,
    bool? networkAvailable,
  }) {
    _currentState = riskState;
    if (batteryLevel != null) _batteryLevel = batteryLevel;
    if (networkAvailable != null) _isNetworkAvailable = networkAvailable;

    _adjustTimer();
  }

  Duration _calculateInterval() {
    // Base interval based on risk state
    int baseSeconds;
    switch (_currentState) {
      case RainRiskState.imminent:
      case RainRiskState.warning:
        baseSeconds = AlertThresholds.warningPolling;
        break;
      case RainRiskState.approaching:
        baseSeconds = AlertThresholds.approachingPolling;
        break;
      case RainRiskState.watch:
        baseSeconds = AlertThresholds.watchPolling;
        break;
      case RainRiskState.raining:
        baseSeconds = AlertThresholds.rainingPolling;
        break;
      default:
        baseSeconds = AlertThresholds.normalPolling;
    }

    // Adjust for battery
    if (_batteryLevel < AlertThresholds.criticalBatteryThreshold) {
      baseSeconds = (baseSeconds * 3).toInt(); // Triple interval
    } else if (_batteryLevel < AlertThresholds.lowBatteryThreshold) {
      baseSeconds = (baseSeconds * 2).toInt(); // Double interval
    }

    // Adjust for network
    if (!_isNetworkAvailable) {
      baseSeconds = (baseSeconds * 2).toInt();
    }

    return Duration(seconds: baseSeconds);
  }

  void _adjustTimer() {
    final newInterval = _calculateInterval();
    _timer?.cancel();
    _timer = Timer.periodic(newInterval, (_) => _onUpdate());
  }

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(_calculateInterval(), (_) => _onUpdate());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    _currentState = RainRiskState.idle;
    _batteryLevel = 100;
    _isNetworkAvailable = true;
    stop();
  }

  void dispose() {
    stop();
  }
}
