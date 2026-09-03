import 'package:flutter_test/flutter_test.dart';
import 'package:rain_guard/domain/entities/location_snapshot.dart';
import 'package:rain_guard/domain/entities/weather_snapshot.dart';
import 'package:rain_guard/domain/entities/precipitation_forecast.dart';
import 'package:rain_guard/domain/entities/geo_point.dart';
import 'package:rain_guard/domain/enums/rain_risk_state.dart';
import 'package:rain_guard/domain/services/precipitation_analyzer.dart';
import 'package:rain_guard/domain/services/rain_arrival_predictor.dart';
import 'package:rain_guard/domain/services/prediction_fusion_engine.dart';

void main() {
  group('PrecipitationAnalyzer', () {
    late PrecipitationAnalyzer analyzer;

    setUp(() {
      analyzer = PrecipitationAnalyzer();
    });

    test('analyzes dry conditions', () {
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

      final forecast = PrecipitationForecast(
        timestamp: DateTime.now(),
        intervals: [],
      );

      final analysis = analyzer.analyze(weather: weather, forecast: forecast);

      expect(analysis.isRaining, false);
      expect(analysis.hasAnyPrecipitation, false);
    });

    test('analyzes raining conditions', () {
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

      final forecast = PrecipitationForecast(
        timestamp: DateTime.now(),
        intervals: [],
      );

      final analysis = analyzer.analyze(weather: weather, forecast: forecast);

      expect(analysis.isRaining, true);
      expect(analysis.hasAnyPrecipitation, true);
    });

    test('analyzes forecast with rain', () {
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

      final now = DateTime.now();
      final forecast = PrecipitationForecast(
        timestamp: now,
        intervals: [
          PrecipitationInterval(
            time: now.add(const Duration(minutes: 15)),
            precipitation: 2.5,
            rain: 2.5,
            showers: 0,
          ),
        ],
      );

      final analysis = analyzer.analyze(weather: weather, forecast: forecast);

      expect(analysis.forecastHasRain, true);
      expect(analysis.forecastFirstRainEta, isNotNull);
    });
  });

  group('RainArrivalPredictor', () {
    late RainArrivalPredictor predictor;

    setUp(() {
      predictor = RainArrivalPredictor();
    });

    test('predicts immediate rain when currently raining', () {
      final location = LocationSnapshot(
        position: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
        accuracy: 10,
        speed: 5,
        bearing: 90,
        timestamp: DateTime.now(),
      );

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

      final forecast = PrecipitationForecast(
        timestamp: DateTime.now(),
        intervals: [],
      );

      final prediction = predictor.predict(
        location: location,
        weather: weather,
        forecast: forecast,
      );

      expect(prediction.state, RainRiskState.raining);
      expect(prediction.eta?.inSeconds, 0);
    });

    test('predicts idle when no rain', () {
      final location = LocationSnapshot(
        position: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
        accuracy: 10,
        speed: 5,
        bearing: 90,
        timestamp: DateTime.now(),
      );

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

      final forecast = PrecipitationForecast(
        timestamp: DateTime.now(),
        intervals: [],
      );

      final prediction = predictor.predict(
        location: location,
        weather: weather,
        forecast: forecast,
      );

      expect(prediction.state, RainRiskState.idle);
    });

    test('predicts watch when rain forecasted in 15 minutes', () {
      final location = LocationSnapshot(
        position: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
        accuracy: 10,
        speed: 5,
        bearing: 90,
        timestamp: DateTime.now(),
      );

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

      final now = DateTime.now();
      final forecast = PrecipitationForecast(
        timestamp: now,
        intervals: [
          PrecipitationInterval(
            time: now.add(const Duration(minutes: 15)),
            precipitation: 2.5,
            rain: 2.5,
            showers: 0,
          ),
        ],
      );

      final prediction = predictor.predict(
        location: location,
        weather: weather,
        forecast: forecast,
      );

      expect(prediction.state, RainRiskState.watch);
    });

    test('etaDisplay returns correct format', () {
      final location = LocationSnapshot(
        position: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
        accuracy: 10,
        speed: 5,
        bearing: 90,
        timestamp: DateTime.now(),
      );

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

      final forecast = PrecipitationForecast(
        timestamp: DateTime.now(),
        intervals: [],
      );

      final prediction = predictor.predict(
        location: location,
        weather: weather,
        forecast: forecast,
      );

      expect(prediction.etaDisplay, 'NOW');
    });
  });

  group('PredictionFusionEngine', () {
    late PredictionFusionEngine engine;

    setUp(() {
      engine = PredictionFusionEngine();
    });

    test('fuses predictions correctly', () {
      final location = LocationSnapshot(
        position: const GeoPoint(latitude: 40.7128, longitude: -74.0060),
        accuracy: 10,
        speed: 5,
        bearing: 90,
        timestamp: DateTime.now(),
      );

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

      final forecast = PrecipitationForecast(
        timestamp: DateTime.now(),
        intervals: [],
      );

      final prediction = engine.fuse(
        location: location,
        weather: weather,
        forecast: forecast,
      );

      expect(prediction, isNotNull);
      expect(prediction.source, 'forecast');
    });
  });
}
