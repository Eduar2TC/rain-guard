import 'dart:math';

import 'package:rain_guard/domain/entities/rain_event.dart';
import 'package:rain_guard/domain/entities/weather_snapshot.dart';
import 'package:rain_guard/domain/entities/geo_point.dart';
import 'package:rain_guard/domain/enums/rain_intensity.dart';
import 'package:rain_guard/core/constants/alert_thresholds.dart';

class RainEventDetector {
  RainEvent? _activeEvent;
  final List<RainEvent> _eventHistory = [];

  RainEvent? get activeEvent => _activeEvent;
  List<RainEvent> get eventHistory => List.unmodifiable(_eventHistory);

  /// Check if a rain event is starting or ending
  RainEventDetection detect({
    required WeatherSnapshot weather,
    required GeoPoint? location,
  }) {
    final isRaining = weather.precipitation > AlertThresholds.lightRain;
    final hasActiveEvent = _activeEvent != null;

    // Rain is starting
    if (isRaining && !hasActiveEvent) {
      _activeEvent = RainEvent(
        id: _generateId(),
        startedAt: DateTime.now(),
        location: location,
        maxIntensity: RainIntensity.fromMmPerHour(weather.precipitation),
      );
      return RainEventDetection(
        type: RainEventDetectionType.started,
        event: _activeEvent,
      );
    }

    // Rain is continuing
    if (isRaining && hasActiveEvent) {
      // Update max intensity if needed
      final currentIntensity = RainIntensity.fromMmPerHour(weather.precipitation);
      if (_intensityIndex(currentIntensity) > _intensityIndex(_activeEvent!.maxIntensity)) {
        _activeEvent = _activeEvent!.copyWith(
          maxIntensity: currentIntensity,
        );
      }
      return RainEventDetection(
        type: RainEventDetectionType.continuing,
        event: _activeEvent,
      );
    }

    // Rain has stopped
    if (!isRaining && hasActiveEvent) {
      final endedEvent = _activeEvent!.copyWith(
        endedAt: DateTime.now(),
      );
      _eventHistory.add(endedEvent);
      _activeEvent = null;
      return RainEventDetection(
        type: RainEventDetectionType.ended,
        event: endedEvent,
      );
    }

    // No rain, no event
    return const RainEventDetection(
      type: RainEventDetectionType.none,
      event: null,
    );
  }

  int _intensityIndex(RainIntensity intensity) {
    switch (intensity) {
      case RainIntensity.none:
        return 0;
      case RainIntensity.light:
        return 1;
      case RainIntensity.moderate:
        return 2;
      case RainIntensity.heavy:
        return 3;
      case RainIntensity.extreme:
        return 4;
    }
  }

  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = Random.secure().nextInt(0xFFFFFF);
    return 'rain_event_${now}_$rand';
  }

  void reset() {
    _activeEvent = null;
    _eventHistory.clear();
  }
}

enum RainEventDetectionType {
  none,
  started,
  continuing,
  ended,
}

class RainEventDetection {
  final RainEventDetectionType type;
  final RainEvent? event;

  const RainEventDetection({
    required this.type,
    this.event,
  });

  bool get hasEvent => event != null;
  bool get isStarting => type == RainEventDetectionType.started;
  bool get isEnding => type == RainEventDetectionType.ended;
  bool get isContinuing => type == RainEventDetectionType.continuing;
}
