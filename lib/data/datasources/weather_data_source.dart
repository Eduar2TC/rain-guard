import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/weather_api.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entities/geo_point.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/entities/precipitation_forecast.dart';

class WeatherDataSource {
  final http.Client _client;
  final Duration _timeout;

  WeatherDataSource({
    http.Client? client,
    Duration? timeout,
  })  : _client = client ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 10);

  Future<Map<String, dynamic>?> fetchWeatherData(GeoPoint location) async {
    try {
      final url = WeatherApiConstants.buildUrl(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      final response = await _client
          .get(Uri.parse(url))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      logger.warning(LogTags.weather, 'Weather API error: $e');
      return null;
    }
  }

  WeatherSnapshot? parseWeatherSnapshot(Map<String, dynamic> json) {
    try {
      final current = json['current'];
      if (current == null) return null;

      return WeatherSnapshot(
        timestamp: DateTime.now(),
        sourceTimestamp: DateTime.now(),
        precipitation: (current['precipitation'] as num?)?.toDouble() ?? 0.0,
        rain: (current['rain'] as num?)?.toDouble() ?? 0.0,
        showers: (current['showers'] as num?)?.toDouble() ?? 0.0,
        temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
        windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
        windDirection: (current['wind_direction_10m'] as num?)?.toDouble() ?? 0.0,
        windGust: (current['wind_gusts_10m'] as num?)?.toDouble() ?? 0.0,
        weatherCode: current['weather_code'] as int? ?? 0,
      );
    } catch (e) {
      logger.warning(LogTags.weather, 'Parse weather error: $e');
      return null;
    }
  }

  PrecipitationForecast? parsePrecipitationForecast(Map<String, dynamic> json) {
    try {
      final minutely15 = json['minutely_15'];
      if (minutely15 == null) return null;

      final precipitationData = minutely15['precipitation'] as List?;
      final timeData = minutely15['time'] as List?;
      if (precipitationData == null || timeData == null) return null;

      final intervals = <PrecipitationInterval>[];
      final now = DateTime.now();

      // Open-Meteo returns 15-minute intervals with actual timestamps
      // Filter to only include future intervals within the next 2 hours
      for (int i = 0; i < precipitationData.length; i++) {
        final intervalTime = DateTime.parse(timeData[i] as String);

        // Only include future intervals within the next 2 hours
        if (intervalTime.isAfter(now) && intervalTime.difference(now).inMinutes <= 120) {
          final precipitation = (precipitationData[i] as num?)?.toDouble() ?? 0.0;

          intervals.add(PrecipitationInterval(
            time: intervalTime,
            precipitation: precipitation,
            rain: precipitation, // Approximate
            showers: precipitation > 0 ? precipitation * 0.5 : 0,
          ));
        }
      }

      return PrecipitationForecast(
        timestamp: DateTime.now(),
        intervals: intervals,
      );
    } catch (e) {
      logger.warning(LogTags.weather, 'Parse forecast error: $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
