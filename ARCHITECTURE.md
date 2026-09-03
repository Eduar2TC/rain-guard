# RainGuard — Arquitectura y Modelos

## Enums

```dart
// lib/domain/enums/rain_risk_state.dart
enum RainRiskState {
  idle,
  watch,
  approaching,
  warning,
  imminent,
  raining,
  passed,
  unknown
}

// lib/domain/enums/rain_intensity.dart
enum RainIntensity {
  none,
  light,
  moderate,
  heavy,
  extreme
}

// lib/domain/enums/prediction_confidence.dart
enum PredictionConfidence {
  none,      // < 0.40
  low,       // 0.40 - 0.59
  medium,    // 0.60 - 0.79
  high       // >= 0.80
}

// lib/domain/enums/network_state.dart
enum NetworkState {
  wifi,
  mobile,
  noConnection
}

// lib/domain/enums/monitoring_mode.dart
enum MonitoringMode {
  quiet,      // Solo burbuja
  vibration,  // Burbuja + vibración
  sound,      // Burbuja + sonido
  full        // Burbuja + sonido + vibración + notificación
}

// lib/domain/enums/alert_priority.dart
enum AlertPriority {
  low,
  normal,
  high,
  critical
}

// lib/domain/enums/movement_state.dart
enum MovementState {
  stopped,    // < 1 km/h
  slow,       // 1-8 km/h
  cycling,    // 8-30 km/h
  fast        // > 30 km/h
}
```

## Entities

```dart
// lib/domain/entities/geo_point.dart
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({required this.latitude, required this.longitude});

  static double distanceBetween(GeoPoint a, GeoPoint b) { ... }
  static double bearingBetween(GeoPoint a, GeoPoint b) { ... }
  static GeoPoint projectPoint(GeoPoint origin, double bearing, double distance) { ... }
}

// lib/domain/entities/location_snapshot.dart
class LocationSnapshot {
  final GeoPoint position;
  final double accuracy;
  final double speed;
  final double bearing;
  final DateTime timestamp;

  const LocationSnapshot({
    required this.position,
    required this.accuracy,
    required this.speed,
    required this.bearing,
    required this.timestamp,
  });

  MovementState get movementState {
    final speedKmh = speed * 3.6;
    if (speedKmh < 1) return MovementState.stopped;
    if (speedKmh < 8) return MovementState.slow;
    if (speedKmh < 30) return MovementState.cycling;
    return MovementState.fast;
  }
}

// lib/domain/entities/weather_snapshot.dart
class WeatherSnapshot {
  final DateTime timestamp;
  final DateTime sourceTimestamp;
  final double precipitation;
  final double rain;
  final double showers;
  final double temperature;
  final double windSpeed;
  final double windDirection;
  final double windGust;
  final int weatherCode;

  const WeatherSnapshot({ ... });
}

// lib/domain/entities/precipitation_forecast.dart
class PrecipitationForecast {
  final DateTime timestamp;
  final List<PrecipitationInterval> intervals;

  const PrecipitationForecast({ ... });
}

class PrecipitationInterval {
  final DateTime time;
  final double precipitation;
  final double rain;
  final double showers;
}

// lib/domain/entities/rain_arrival_prediction.dart
class RainArrivalPrediction {
  final RainRiskState state;
  final Duration? etaMinutes;
  final double? distanceMeters;
  final RainIntensity intensity;
  final PredictionConfidence confidence;
  final double? direction;
  final String source;
  final DateTime timestamp;

  const RainArrivalPrediction({ ... });
}

// lib/domain/entities/monitoring_state.dart
class MonitoringState {
  final bool isMonitoring;
  final RainRiskState riskState;
  final Duration? etaMinutes;
  final PredictionConfidence confidence;
  final RainIntensity rainIntensity;
  final double? latitude;
  final double? longitude;
  final double speed;
  final double bearing;
  final DateTime? lastUpdate;
  final Duration? dataAge;
  final bool networkAvailable;
  final double batteryLevel;
  final bool bubbleVisible;
  final MonitoringMode monitoringMode;

  const MonitoringState({ ... });

  MonitoringState copyWith({ ... });
}

// lib/domain/entities/rain_event.dart
class RainEvent {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final GeoPoint? location;
  final RainIntensity maxIntensity;
  final Duration? predictedEta;
  final PredictionConfidence predictionConfidence;
  final bool? actualRainDetected;

  const RainEvent({ ... });
}

// lib/domain/entities/alert_decision.dart
class AlertDecision {
  final bool shouldNotify;
  final RainRiskState newState;
  final String message;
  final AlertPriority priority;
  final bool playSound;
  final bool vibrate;

  const AlertDecision({ ... });
}
```

## Repositories (Interfaces)

```dart
// lib/domain/repositories/weather_repository.dart
abstract class WeatherRepository {
  Future<WeatherSnapshot> getCurrentWeather(GeoPoint location);
  Future<PrecipitationForecast> getPrecipitationForecast(GeoPoint location);
  Future<NetworkState> getNetworkState();
}

// lib/domain/repositories/location_repository.dart
abstract class LocationRepository {
  Stream<LocationSnapshot> getLocationUpdates();
  Future<LocationSnapshot?> getLastKnownLocation();
  Future<void> startUpdates();
  Future<void> stopUpdates();
}

// lib/domain/repositories/monitoring_repository.dart
abstract class MonitoringRepository {
  Stream<MonitoringState> getMonitoringState();
  Future<void> startMonitoring();
  Future<void> stopMonitoring();
  Future<void> pauseMonitoring();
  Future<void> resumeMonitoring();
}

// lib/domain/repositories/settings_repository.dart
abstract class SettingsRepository {
  Future<MonitoringMode> getMonitoringMode();
  Future<void> setMonitoringMode(MonitoringMode mode);
  Future<bool> isBubbleEnabled();
  Future<void> setBubbleEnabled(bool enabled);
  // ... more settings
}

// lib/domain/repositories/rain_event_repository.dart
abstract class RainEventRepository {
  Future<void> recordEvent(RainEvent event);
  Future<List<RainEvent>> getEvents({DateTime? from, DateTime? to});
}
```

## Use Cases

```dart
// lib/application/use_cases/start_monitoring.dart
class StartMonitoring {
  final MonitoringRepository monitoringRepo;
  final LocationRepository locationRepo;

  Future<void> call() async {
    await locationRepo.startUpdates();
    await monitoringRepo.startMonitoring();
  }
}

// lib/application/use_cases/stop_monitoring.dart
class StopMonitoring { ... }

// lib/application/use_cases/fetch_weather.dart
class FetchWeather {
  final WeatherRepository weatherRepo;
  final LocationRepository locationRepo;

  Future<WeatherSnapshot?> call() async {
    final location = await locationRepo.getLastKnownLocation();
    if (location == null) return null;
    return await weatherRepo.getCurrentWeather(location.position);
  }
}

// lib/application/use_cases/predict_rain_arrival.dart
class PredictRainArrival {
  final RainArrivalPredictor predictor;

  RainArrivalPrediction call({
    required LocationSnapshot location,
    required WeatherSnapshot weather,
    PrecipitationForecast? forecast,
  }) {
    return predictor.predict(
      location: location,
      weather: weather,
      forecast: forecast,
    );
  }
}

// lib/application/use_cases/evaluate_alert.dart
class EvaluateAlert {
  final AlertEngine alertEngine;

  AlertDecision call({
    required RainArrivalPrediction prediction,
    required MonitoringState currentState,
  }) {
    return alertEngine.evaluate(prediction, currentState);
  }
}
```

## State (Riverpod)

```dart
// lib/application/state/monitoring_state_provider.dart
final monitoringStateProvider = StateNotifierProvider<MonitoringStateNotifier, MonitoringState>(
  (ref) => MonitoringStateNotifier(ref),
);

class MonitoringStateNotifier extends StateNotifier<MonitoringState> {
  // Manages monitoring state
  // Listens to platform channels
  // Updates UI
}
```

## Platform Channels

```dart
// lib/platform/channels/method_channel_service.dart
class MethodChannelService {
  static const _channel = MethodChannel('rain_guard/monitoring');

  Future<void> startMonitoring() => _channel.invokeMethod('startMonitoring');
  Future<void> stopMonitoring() => _channel.invokeMethod('stopMonitoring');
  Future<void> showBubble() => _channel.invokeMethod('showBubble');
  Future<void> hideBubble() => _channel.invokeMethod('hideBubble');
  Future<void> setSettings(Map<String, dynamic> settings) =>
    _channel.invokeMethod('setSettings', settings);
}

// lib/platform/channels/event_channel_service.dart
class EventChannelService {
  static const _channel = EventChannel('rain_guard/events');

  Stream<MonitoringState> get monitoringState {
    return _channel.receiveBroadcastStream().map((event) {
      return MonitoringState.fromMap(Map<String, dynamic>.from(event));
    });
  }
}
```

## Android Service

```kotlin
// android/app/src/main/kotlin/.../service/RainMonitorForegroundService.kt
class RainMonitorForegroundService : Service() {
    private val locationManager = LocationManager(this)
    private val weatherManager = WeatherPlatformBridge(this)
    private val notificationManager = RainNotificationManager(this)
    private val overlayManager = RainBubbleManager(this)
    private val alertEngine = AlertEngine()

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, notificationManager.createNotification())
        startLocationUpdates()
        startWeatherPolling()
        return START_STICKY
    }

    private fun startWeatherPolling() {
        // Adaptive polling based on risk state
    }
}
```
