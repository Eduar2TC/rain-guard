import '../entities/monitoring_state.dart';

abstract class MonitoringRepository {
  Stream<MonitoringState> getMonitoringState();
  Future<void> startMonitoring();
  Future<void> stopMonitoring();
  Future<void> pauseMonitoring();
  Future<void> resumeMonitoring();
  Future<bool> isActive();
}
