import 'package:flutter_test/flutter_test.dart';
import 'package:rain_guard/domain/entities/weather_snapshot.dart';
import 'package:rain_guard/domain/entities/geo_point.dart';
import 'package:rain_guard/domain/services/rain_event_detector.dart';

void main() {
  group('RainEventDetector', () {
    late RainEventDetector detector;

    setUp(() {
      detector = RainEventDetector();
    });

    test('detects no event when not raining', () {
      final weather = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 0,
        rain: 0,
        showers: 0,
        temperature: 20,
        windSpeed: 10,
        windDirection: 180,
        windGust: 15,
        weatherCode: 0,
      );

      final detection = detector.detect(
        weather: weather,
        location: const GeoPoint(latitude: 0, longitude: 0),
      );

      expect(detection.type, RainEventDetectionType.none);
      expect(detection.hasEvent, false);
    });

    test('detects rain event starting', () {
      final weather = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 2.5,
        rain: 2.5,
        showers: 0,
        temperature: 18,
        windSpeed: 15,
        windDirection: 180,
        windGust: 20,
        weatherCode: 61,
      );

      final detection = detector.detect(
        weather: weather,
        location: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
      );

      expect(detection.type, RainEventDetectionType.started);
      expect(detection.hasEvent, true);
      expect(detection.isStarting, true);
    });

    test('detects rain event continuing', () {
      final weather = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 2.5,
        rain: 2.5,
        showers: 0,
        temperature: 18,
        windSpeed: 15,
        windDirection: 180,
        windGust: 20,
        weatherCode: 61,
      );

      // First detection - starts
      detector.detect(
        weather: weather,
        location: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
      );

      // Second detection - continues
      final detection = detector.detect(
        weather: weather,
        location: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
      );

      expect(detection.type, RainEventDetectionType.continuing);
      expect(detection.isContinuing, true);
    });

    test('detects rain event ending', () {
      final raining = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 2.5,
        rain: 2.5,
        showers: 0,
        temperature: 18,
        windSpeed: 15,
        windDirection: 180,
        windGust: 20,
        weatherCode: 61,
      );

      final notRaining = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 0,
        rain: 0,
        showers: 0,
        temperature: 20,
        windSpeed: 10,
        windDirection: 180,
        windGust: 15,
        weatherCode: 0,
      );

      // Start rain
      detector.detect(
        weather: raining,
        location: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
      );

      // End rain
      final detection = detector.detect(
        weather: notRaining,
        location: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
      );

      expect(detection.type, RainEventDetectionType.ended);
      expect(detection.isEnding, true);
    });

    test('tracks event history', () {
      final raining = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 2.5,
        rain: 2.5,
        showers: 0,
        temperature: 18,
        windSpeed: 15,
        windDirection: 180,
        windGust: 20,
        weatherCode: 61,
      );

      final notRaining = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 0,
        rain: 0,
        showers: 0,
        temperature: 20,
        windSpeed: 10,
        windDirection: 180,
        windGust: 15,
        weatherCode: 0,
      );

      // Start and end rain
      detector.detect(
        weather: raining,
        location: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
      );
      detector.detect(
        weather: notRaining,
        location: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
      );

      expect(detector.eventHistory.length, 1);
      expect(detector.activeEvent, null);
    });

    test('updates max intensity during event', () {
      final lightRain = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 1.0,
        rain: 1.0,
        showers: 0,
        temperature: 18,
        windSpeed: 15,
        windDirection: 180,
        windGust: 20,
        weatherCode: 61,
      );

      final heavyRain = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 10.0,
        rain: 10.0,
        showers: 0,
        temperature: 18,
        windSpeed: 15,
        windDirection: 180,
        windGust: 20,
        weatherCode: 61,
      );

      // Start with light rain
      detector.detect(
        weather: lightRain,
        location: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
      );

      // Continue with heavy rain
      detector.detect(
        weather: heavyRain,
        location: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
      );

      expect(detector.activeEvent?.maxIntensity.name, 'heavy');
    });

    test('reset clears state', () {
      final weather = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 2.5,
        rain: 2.5,
        showers: 0,
        temperature: 18,
        windSpeed: 15,
        windDirection: 180,
        windGust: 20,
        weatherCode: 61,
      );

      detector.detect(
        weather: weather,
        location: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
      );

      detector.reset();

      expect(detector.activeEvent, null);
      expect(detector.eventHistory, isEmpty);
    });
  });
}
