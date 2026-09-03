import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../state/location_state_provider.dart';
import '../state/weather_state_provider.dart';
import '../state/prediction_state_provider.dart';
import '../state/alert_state_provider.dart';
import '../state/monitoring_service_provider.dart';
import '../state/battery_state_provider.dart';
import '../state/bubble_state_provider.dart';

// Debug State
class DebugState {
  final bool isDebugMode;
  final List<LogEntry> logs;
  final Map<String, dynamic> systemInfo;

  const DebugState({
    this.isDebugMode = false,
    this.logs = const [],
    this.systemInfo = const {},
  });

  DebugState copyWith({
    bool? isDebugMode,
    List<LogEntry>? logs,
    Map<String, dynamic>? systemInfo,
  }) {
    return DebugState(
      isDebugMode: isDebugMode ?? this.isDebugMode,
      logs: logs ?? this.logs,
      systemInfo: systemInfo ?? this.systemInfo,
    );
  }
}

// Debug State Notifier
class DebugStateNotifier extends StateNotifier<DebugState> {
  final Ref _ref;
  Timer? _refreshTimer;

  DebugStateNotifier(this._ref) : super(const DebugState()) {
    _init();
  }

  void _init() {
    logger.info(LogTags.monitoring, 'Debug mode initialized');
  }

  void toggleDebugMode() {
    state = state.copyWith(isDebugMode: !state.isDebugMode);
    logger.info(LogTags.monitoring, 'Debug mode: ${state.isDebugMode}');
  }

  void refreshLogs() {
    state = state.copyWith(logs: logger.getRecentLogs(count: 200));
  }

  void refreshSystemInfo() {
    final locationState = _ref.read(locationStateProvider);
    final weatherState = _ref.read(weatherStateProvider);
    final predictionState = _ref.read(predictionStateProvider);
    final alertState = _ref.read(alertStateProvider);
    final monitoringState = _ref.read(monitoringServiceProvider);
    final batteryState = _ref.read(batteryStateProvider);
    final bubbleState = _ref.read(bubbleStateProvider);

    state = state.copyWith(systemInfo: {
      // Location
      'latitude': locationState.currentLocation?.position.latitude,
      'longitude': locationState.currentLocation?.position.longitude,
      'accuracy': locationState.currentLocation?.accuracy,
      'speed': locationState.currentLocation?.speed,
      'bearing': locationState.currentLocation?.bearing,
      'locationPermission': locationState.hasPermission,
      'backgroundPermission': locationState.hasBackgroundPermission,

      // Weather
      'precipitation': weatherState.currentWeather?.precipitation,
      'temperature': weatherState.currentWeather?.temperature,
      'windSpeed': weatherState.currentWeather?.windSpeed,
      'weatherDataAge': weatherState.dataAge?.inSeconds,
      'weatherNetwork': weatherState.networkState.name,

      // Prediction
      'riskState': predictionState.riskState.name,
      'etaMinutes': predictionState.etaMinutes,
      'confidence': predictionState.confidence.name,
      'predictionSource': predictionState.prediction?.source,

      // Alert
      'alertState': alertState.currentState.name,
      'alertEnabled': alertState.alertsEnabled,
      'hasActiveEvent': alertState.hasActiveEvent,

      // Monitoring
      'isMonitoring': monitoringState.isMonitoring,
      'isPaused': monitoringState.isPaused,

      // Battery
      'batteryLevel': batteryState.percentage,
      'isCharging': batteryState.isCharging,
      'isPowerSaveMode': batteryState.isPowerSaveMode,
      'batteryOptimized': batteryState.isIgnoringBatteryOptimizations,

      // Bubble
      'bubbleVisible': bubbleState.isVisible,
      'bubbleState': bubbleState.currentState,
    });
  }

  void startAutoRefresh({Duration interval = const Duration(seconds: 2)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) {
      refreshLogs();
      refreshSystemInfo();
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void clearLogs() {
    logger.clear();
    refreshLogs();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

// Provider
final debugStateProvider = StateNotifierProvider<DebugStateNotifier, DebugState>((ref) {
  return DebugStateNotifier(ref);
});
