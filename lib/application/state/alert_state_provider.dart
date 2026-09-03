import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/rain_arrival_prediction.dart';
import '../../domain/entities/monitoring_state.dart';
import '../../domain/entities/alert_decision.dart';
import '../../domain/entities/rain_event.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/enums/rain_risk_state.dart';
import '../../domain/services/alert_engine.dart';
import '../../domain/services/rain_event_detector.dart';
import '../../platform/channels/method_channel_service.dart';
import 'prediction_state_provider.dart';
import 'location_state_provider.dart';
import 'weather_state_provider.dart';

// Provider for AlertEngine
final alertEngineProvider = Provider<AlertEngine>((ref) {
  return AlertEngine();
});

// Provider for RainEventDetector
final rainEventDetectorProvider = Provider<RainEventDetector>((ref) {
  return RainEventDetector();
});

// Alert State
class AlertState {
  final RainRiskState currentState;
  final AlertDecision? lastDecision;
  final RainEvent? activeEvent;
  final List<RainEvent> eventHistory;
  final DateTime? lastAlertTime;
  final bool alertsEnabled;

  const AlertState({
    this.currentState = RainRiskState.idle,
    this.lastDecision,
    this.activeEvent,
    this.eventHistory = const [],
    this.lastAlertTime,
    this.alertsEnabled = true,
  });

  bool get isRaining => currentState == RainRiskState.raining;
  bool get hasActiveEvent => activeEvent != null;

  AlertState copyWith({
    RainRiskState? currentState,
    AlertDecision? lastDecision,
    RainEvent? activeEvent,
    List<RainEvent>? eventHistory,
    DateTime? lastAlertTime,
    bool? alertsEnabled,
  }) {
    return AlertState(
      currentState: currentState ?? this.currentState,
      lastDecision: lastDecision ?? this.lastDecision,
      activeEvent: activeEvent ?? this.activeEvent,
      eventHistory: eventHistory ?? this.eventHistory,
      lastAlertTime: lastAlertTime ?? this.lastAlertTime,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
    );
  }
}

// Alert State Notifier
class AlertStateNotifier extends StateNotifier<AlertState> {
  final AlertEngine _alertEngine;
  final RainEventDetector _eventDetector;
  final MethodChannelService _methodChannel;

  AlertStateNotifier({
    required AlertEngine alertEngine,
    required RainEventDetector eventDetector,
    required MethodChannelService methodChannel,
  })  : _alertEngine = alertEngine,
        _eventDetector = eventDetector,
        _methodChannel = methodChannel,
        super(const AlertState());

  void processPrediction(RainArrivalPrediction prediction) {
    if (!state.alertsEnabled) return;

    // Create current monitoring state from alert state
    final currentState = MonitoringState(
      riskState: state.currentState,
      isPaused: false,
    );

    // Evaluate alert
    final decision = _alertEngine.evaluate(
      prediction: prediction,
      currentState: currentState,
    );

    if (decision.shouldNotify) {
      // Update state
      state = state.copyWith(
        currentState: decision.newState,
        lastDecision: decision,
        lastAlertTime: DateTime.now(),
      );

      // Send notification via platform channel
      _sendNotification(decision);

      // Play sound/vibrate if needed
      if (decision.playSound) {
        _methodChannel.playAlertSound();
      }
      if (decision.vibrate) {
        _methodChannel.vibrate();
      }
    }
  }

  void processWeatherUpdate({
    required double precipitation,
    required GeoPoint? location,
  }) {
    // Detect rain events
    final weatherSnapshot = WeatherSnapshot(
      timestamp: DateTime.now(),
      sourceTimestamp: DateTime.now(),
      precipitation: precipitation,
      rain: precipitation,
      showers: 0,
      temperature: 0,
      windSpeed: 0,
      windDirection: 0,
      windGust: 0,
      weatherCode: 0,
    );

    final detection = _eventDetector.detect(
      weather: weatherSnapshot,
      location: location,
    );

    if (detection.isStarting) {
      state = state.copyWith(
        activeEvent: detection.event,
      );
    } else if (detection.isEnding) {
      state = state.copyWith(
        activeEvent: null,
        eventHistory: [...state.eventHistory, detection.event!],
      );
    }
  }

  void _sendNotification(AlertDecision decision) {
    // This will be handled by the foreground service
    // For now, we just log it
    print('Alert: ${decision.message}');
  }

  void toggleAlerts() {
    state = state.copyWith(
      alertsEnabled: !state.alertsEnabled,
    );
  }

  void clearHistory() {
    _eventDetector.reset();
    state = state.copyWith(
      eventHistory: [],
      activeEvent: null,
    );
  }

  void reset() {
    _alertEngine.reset();
    _eventDetector.reset();
    state = const AlertState();
  }
}

// Provider
final alertStateProvider = StateNotifierProvider<AlertStateNotifier, AlertState>((ref) {
  final alertEngine = ref.watch(alertEngineProvider);
  final eventDetector = ref.watch(rainEventDetectorProvider);
  final methodChannel = ref.watch(methodChannelServiceProvider);

  return AlertStateNotifier(
    alertEngine: alertEngine,
    eventDetector: eventDetector,
    methodChannel: methodChannel,
  );
});
