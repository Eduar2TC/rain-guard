import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/location_snapshot.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/entities/precipitation_forecast.dart';
import '../../domain/entities/rain_arrival_prediction.dart';
import '../../domain/enums/rain_risk_state.dart';
import '../../platform/channels/method_channel_service.dart';
import '../../platform/channels/event_channel_service.dart';
import '../state/location_state_provider.dart';
import '../state/weather_state_provider.dart';
import '../state/prediction_state_provider.dart';
import '../state/alert_state_provider.dart';
import '../../domain/services/monitoring_scheduler.dart';

// Provider for MethodChannelService
final methodChannelServiceProvider = Provider<MethodChannelService>((ref) {
  return MethodChannelService();
});

// Provider for EventChannelService
final eventChannelServiceProvider = Provider<EventChannelService>((ref) {
  return EventChannelService();
});

// Monitoring State
class MonitoringServiceState {
  final bool isMonitoring;
  final bool isPaused;
  final String? error;

  const MonitoringServiceState({
    this.isMonitoring = false,
    this.isPaused = false,
    this.error,
  });

  MonitoringServiceState copyWith({
    bool? isMonitoring,
    bool? isPaused,
    String? error,
  }) {
    return MonitoringServiceState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      isPaused: isPaused ?? this.isPaused,
      error: error,
    );
  }
}

// Monitoring Service Notifier
class MonitoringServiceNotifier extends StateNotifier<MonitoringServiceState> {
  final MethodChannelService _methodChannel;
  final EventChannelService _eventChannel;
  final Ref _ref;

  MonitoringScheduler? _scheduler;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _weatherSubscription;

  MonitoringServiceNotifier(this._methodChannel, this._eventChannel, this._ref)
      : super(const MonitoringServiceState()) {
    _init();
  }

  void _init() {
    _eventChannel.startListening();
  }

  Future<void> startMonitoring() async {
    try {
      state = state.copyWith(isMonitoring: true, error: null);

      // Start location updates
      await _methodChannel.startMonitoring();

      // Start listening to location updates
      _locationSubscription = _eventChannel.locationUpdates.listen(
        (location) {
          _onLocationUpdate(location);
        },
        onError: (error) {
          state = state.copyWith(error: error.toString());
        },
      );

      // Create and start scheduler
      _scheduler = MonitoringScheduler(
        onUpdate: _pollWeather,
      );
      _scheduler?.start();

    } catch (e) {
      state = state.copyWith(
        isMonitoring: false,
        error: e.toString(),
      );
    }
  }

  Future<void> stopMonitoring() async {
    try {
      state = state.copyWith(isMonitoring: false, isPaused: false, error: null);

      await _methodChannel.stopMonitoring();
      _locationSubscription?.cancel();
      _scheduler?.dispose();
      _scheduler = null;

    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> pauseMonitoring() async {
    try {
      state = state.copyWith(isPaused: true);
      await _methodChannel.pauseMonitoring();
      _scheduler?.stop();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> resumeMonitoring() async {
    try {
      state = state.copyWith(isPaused: false);
      await _methodChannel.resumeMonitoring();
      _scheduler?.start();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void _onLocationUpdate(LocationSnapshot location) {
    // Update location state
    _ref.read(locationStateProvider.notifier).updateLocation(location);

    // Trigger weather fetch
    _pollWeather();
  }

  Future<void> _pollWeather() async {
    final location = _ref.read(locationStateProvider).currentLocation;
    if (location == null) return;

    try {
      // Fetch weather
      await _ref.read(weatherStateProvider.notifier).fetchWeather(location.position);

      final weather = _ref.read(weatherStateProvider).currentWeather;
      final forecast = _ref.read(weatherStateProvider).forecast;

      if (weather != null && forecast != null) {
        // Update prediction
        _ref.read(predictionStateProvider.notifier).updatePrediction(
              location: location,
              weather: weather,
              forecast: forecast,
            );

        final prediction = _ref.read(predictionStateProvider).prediction;
        if (prediction != null) {
          // Process alert
          _ref.read(alertStateProvider.notifier).processPrediction(prediction);

          // Update scheduler based on state
          final alertState = _ref.read(alertStateProvider);
          _scheduler?.update(
            riskState: alertState.currentState,
            batteryLevel: 100, // TODO: Get actual battery level
            networkAvailable: true, // TODO: Get actual network state
          );
        }
      }
    } catch (e) {
      print('Poll weather error: $e');
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _scheduler?.dispose();
    _eventChannel.dispose();
    super.dispose();
  }
}

// Provider
final monitoringServiceProvider = StateNotifierProvider<MonitoringServiceNotifier, MonitoringServiceState>((ref) {
  final methodChannel = ref.watch(methodChannelServiceProvider);
  final eventChannel = ref.watch(eventChannelServiceProvider);
  return MonitoringServiceNotifier(methodChannel, eventChannel, ref);
});
