import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rain_guard/domain/entities/location_snapshot.dart';
import 'package:rain_guard/domain/enums/network_state.dart';
import 'package:rain_guard/platform/channels/method_channel_service.dart';
import 'package:rain_guard/platform/channels/event_channel_service.dart';
import 'package:rain_guard/application/state/providers.dart';
import 'package:rain_guard/application/state/location_state_provider.dart';
import 'package:rain_guard/application/state/weather_state_provider.dart';
import 'package:rain_guard/application/state/prediction_state_provider.dart';
import 'package:rain_guard/application/state/alert_state_provider.dart';
import 'package:rain_guard/application/state/battery_state_provider.dart';
import 'package:rain_guard/domain/services/monitoring_scheduler.dart';

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
  bool _isPolling = false;

  MonitoringServiceNotifier(this._methodChannel, this._eventChannel, this._ref)
      : super(const MonitoringServiceState());

  Future<void> startMonitoring() async {
    try {
      state = state.copyWith(isMonitoring: true, error: null);

      // Start the foreground service (native background monitoring).
      await _methodChannel.startMonitoring();

      // Start location updates on the Android side so location events flow
      // to Flutter over the event channel.
      await _ref.read(locationStateProvider.notifier).startUpdates();

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
      _locationSubscription?.cancel();
      _locationSubscription = null;
      _ref.read(locationStateProvider.notifier).stopUpdates();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> resumeMonitoring() async {
    try {
      state = state.copyWith(isPaused: false);
      await _methodChannel.resumeMonitoring();

      // Re-establish location listening
      _locationSubscription?.cancel();
      _locationSubscription = _eventChannel.locationUpdates.listen(
        (location) {
          _onLocationUpdate(location);
        },
        onError: (error) {
          state = state.copyWith(error: error.toString());
        },
      );

      _scheduler?.start();
      _ref.read(locationStateProvider.notifier).startUpdates();
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
    if (_isPolling) return;
    _isPolling = true;

    try {
      final location = _ref.read(locationStateProvider).currentLocation;
      if (location == null) return;

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
          final batteryState = _ref.read(batteryStateProvider);
          final networkState = _ref.read(weatherStateProvider).networkState;
          _scheduler?.update(
            riskState: alertState.currentState,
            batteryLevel: batteryState.percentage,
            networkAvailable: networkState != NetworkState.noConnection,
          );
        }
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      _isPolling = false;
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _scheduler?.dispose();
    super.dispose();
  }
}

// Provider
final monitoringServiceProvider = StateNotifierProvider<MonitoringServiceNotifier, MonitoringServiceState>((ref) {
  final methodChannel = ref.watch(methodChannelServiceProvider);
  final eventChannel = ref.watch(eventChannelServiceProvider);
  return MonitoringServiceNotifier(methodChannel, eventChannel, ref);
});
