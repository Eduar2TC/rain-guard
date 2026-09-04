import 'package:rain_guard/domain/enums/monitoring_mode.dart';

abstract class SettingsRepository {
  Future<MonitoringMode> getMonitoringMode();
  Future<void> setMonitoringMode(MonitoringMode mode);
  Future<bool> isBubbleEnabled();
  Future<void> setBubbleEnabled(bool enabled);
  Future<bool> isSoundEnabled();
  Future<void> setSoundEnabled(bool enabled);
  Future<bool> isVibrationEnabled();
  Future<void> setVibrationEnabled(bool enabled);
  Future<int> getPollingIntervalSeconds();
  Future<void> setPollingIntervalSeconds(int seconds);
  Future<double> getMinAccuracyMeters();
  Future<void> setMinAccuracyMeters(double meters);
  Future<void> clearAll();
}
