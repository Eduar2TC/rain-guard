import 'package:flutter_test/flutter_test.dart';
import 'package:rain_guard/domain/entities/weather_snapshot.dart';
import 'package:rain_guard/domain/entities/precipitation_forecast.dart';

void main() {
  group('WeatherSnapshot', () {
    test('creates with correct values', () {
      final weather = WeatherSnapshot(
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        sourceTimestamp: DateTime(2024, 1, 1, 12, 0, 0),
        precipitation: 2.5,
        rain: 2.0,
        showers: 0.5,
        temperature: 18.5,
        windSpeed: 15.0,
        windDirection: 180.0,
        windGust: 25.0,
        weatherCode: 61,
      );

      expect(weather.precipitation, 2.5);
      expect(weather.rain, 2.0);
      expect(weather.showers, 0.5);
      expect(weather.temperature, 18.5);
      expect(weather.windSpeed, 15.0);
      expect(weather.windDirection, 180.0);
      expect(weather.windGust, 25.0);
      expect(weather.weatherCode, 61);
    });

    test('isRaining returns true when precipitation > 0.1', () {
      final raining = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 0.5,
        rain: 0.5,
        showers: 0,
        temperature: 18,
        windSpeed: 10,
        windDirection: 180,
        windGust: 15,
        weatherCode: 61,
      );
      expect(raining.isRaining, true);

      final notRaining = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 0,
        rain: 0,
        showers: 0,
        temperature: 18,
        windSpeed: 10,
        windDirection: 180,
        windGust: 15,
        weatherCode: 0,
      );
      expect(notRaining.isRaining, false);
    });

    test('isStale returns true when data is older than 10 minutes', () {
      final stale = WeatherSnapshot(
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        sourceTimestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        precipitation: 0,
        rain: 0,
        showers: 0,
        temperature: 18,
        windSpeed: 10,
        windDirection: 180,
        windGust: 15,
        weatherCode: 0,
      );
      expect(stale.isStale, true);

      final fresh = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 0,
        rain: 0,
        showers: 0,
        temperature: 18,
        windSpeed: 10,
        windDirection: 180,
        windGust: 15,
        weatherCode: 0,
      );
      expect(fresh.isStale, false);
    });

    test('dataAge returns correct duration', () {
      final weather = WeatherSnapshot(
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        sourceTimestamp: DateTime.now(),
        precipitation: 0,
        rain: 0,
        showers: 0,
        temperature: 18,
        windSpeed: 10,
        windDirection: 180,
        windGust: 15,
        weatherCode: 0,
      );

      final age = weather.dataAge;

      expect(age.inMinutes, 5);
    });

    test('copyWith works correctly', () {
      final original = WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: 0,
        rain: 0,
        showers: 0,
        temperature: 18,
        windSpeed: 10,
        windDirection: 180,
        windGust: 15,
        weatherCode: 0,
      );

      final modified = original.copyWith(
        precipitation: 2.5,
        rain: 2.5,
      );

      expect(modified.precipitation, 2.5);
      expect(modified.rain, 2.5);
      expect(modified.temperature, 18); // Unchanged
    });

    test('toMap and fromMap work correctly', () {
      final original = WeatherSnapshot(
        timestamp: DateTime(2024, 1, 1, 12, 0, 0),
        sourceTimestamp: DateTime(2024, 1, 1, 12, 0, 0),
        precipitation: 2.5,
        rain: 2.0,
        showers: 0.5,
        temperature: 18.5,
        windSpeed: 15.0,
        windDirection: 180.0,
        windGust: 25.0,
        weatherCode: 61,
      );

      final map = original.toMap();
      final restored = WeatherSnapshot.fromMap(map);

      expect(restored.precipitation, original.precipitation);
      expect(restored.rain, original.rain);
      expect(restored.temperature, original.temperature);
      expect(restored.weatherCode, original.weatherCode);
    });
  });

  group('PrecipitationForecast', () {
    test('creates with intervals', () {
      final intervals = [
        PrecipitationInterval(
          time: DateTime.now(),
          precipitation: 0,
          rain: 0,
          showers: 0,
        ),
        PrecipitationInterval(
          time: DateTime.now().add(const Duration(minutes: 15)),
          precipitation: 2.5,
          rain: 2.5,
          showers: 0,
        ),
      ];

      final forecast = PrecipitationForecast(
        timestamp: DateTime.now(),
        intervals: intervals,
      );

      expect(forecast.intervals.length, 2);
      expect(forecast.intervals[1].precipitation, 2.5);
    });

    test('firstPrecipitationEta returns correct ETA', () {
      final now = DateTime.now();
      final intervals = [
        PrecipitationInterval(
          time: now.add(const Duration(minutes: 5)),
          precipitation: 0,
          rain: 0,
          showers: 0,
        ),
        PrecipitationInterval(
          time: now.add(const Duration(minutes: 15)),
          precipitation: 2.5,
          rain: 2.5,
          showers: 0,
        ),
      ];

      final forecast = PrecipitationForecast(
        timestamp: now,
        intervals: intervals,
      );

      final eta = forecast.firstPrecipitationEta;
      expect(eta, isNotNull);
      // Allow for the small amount of time that elapses between creating
      // `now` and computing the ETA, which can truncate a fraction of a
      // second off the 15-minute delta.
      expect(eta!.inSeconds, inInclusiveRange(14 * 60, 15 * 60));
    });

    test('firstPrecipitationEta returns null when no rain', () {
      final now = DateTime.now();
      final intervals = [
        PrecipitationInterval(
          time: now.add(const Duration(minutes: 5)),
          precipitation: 0,
          rain: 0,
          showers: 0,
        ),
      ];

      final forecast = PrecipitationForecast(
        timestamp: now,
        intervals: intervals,
      );

      final eta = forecast.firstPrecipitationEta;
      expect(eta, null);
    });

    test('maxPrecipitationInNext15Min returns correct value', () {
      final now = DateTime.now();
      final intervals = [
        PrecipitationInterval(
          time: now.add(const Duration(minutes: 5)),
          precipitation: 1.0,
          rain: 1.0,
          showers: 0,
        ),
        PrecipitationInterval(
          time: now.add(const Duration(minutes: 10)),
          precipitation: 3.0,
          rain: 3.0,
          showers: 0,
        ),
        PrecipitationInterval(
          time: now.add(const Duration(minutes: 20)),
          precipitation: 5.0,
          rain: 5.0,
          showers: 0,
        ),
      ];

      final forecast = PrecipitationForecast(
        timestamp: now,
        intervals: intervals,
      );

      // Should only consider intervals within 15 minutes
      expect(forecast.maxPrecipitationInNext15Min, 3.0);
    });

    test('PrecipitationInterval hasPrecipitation works', () {
      final hasRain = PrecipitationInterval(
        time: DateTime.now(),
        precipitation: 0.5,
        rain: 0.5,
        showers: 0,
      );
      expect(hasRain.hasPrecipitation, true);

      final noRain = PrecipitationInterval(
        time: DateTime.now(),
        precipitation: 0,
        rain: 0,
        showers: 0,
      );
      expect(noRain.hasPrecipitation, false);
    });
  });
}
