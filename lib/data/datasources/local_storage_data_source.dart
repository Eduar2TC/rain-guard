import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/weather_snapshot.dart';
import '../../domain/entities/precipitation_forecast.dart';
import '../../domain/entities/location_snapshot.dart';

class LocalStorageDataSource {
  SharedPreferences? _prefs;

  static const _keyLastWeather = 'last_weather';
  static const _keyLastForecast = 'last_forecast';
  static const _keyLastLocation = 'last_location';
  static const _keyLastUpdate = 'last_update';
  static const _keyWeatherTTL = 'weather_ttl';

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Weather Cache
  Future<void> cacheWeather(WeatherSnapshot weather) async {
    final p = await prefs;
    final json = jsonEncode(weather.toMap());
    await p.setString(_keyLastWeather, json);
    await p.setString(_keyLastUpdate, DateTime.now().toIso8601String());
  }

  Future<WeatherSnapshot?> getCachedWeather() async {
    final p = await prefs;
    final json = p.getString(_keyLastWeather);
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return WeatherSnapshot.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  Future<bool> isWeatherCacheValid({int maxAgeSeconds = 300}) async {
    final p = await prefs;
    final lastUpdateStr = p.getString(_keyLastUpdate);
    if (lastUpdateStr == null) return false;

    final lastUpdate = DateTime.parse(lastUpdateStr);
    final age = DateTime.now().difference(lastUpdate);
    return age.inSeconds < maxAgeSeconds;
  }

  // Forecast Cache
  Future<void> cacheForecast(PrecipitationForecast forecast) async {
    final p = await prefs;
    final json = jsonEncode(forecast.toMap());
    await p.setString(_keyLastForecast, json);
  }

  Future<PrecipitationForecast?> getCachedForecast() async {
    final p = await prefs;
    final json = p.getString(_keyLastForecast);
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return PrecipitationForecast.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  // Location Cache
  Future<void> cacheLocation(LocationSnapshot location) async {
    final p = await prefs;
    final json = jsonEncode(location.toMap());
    await p.setString(_keyLastLocation, json);
  }

  Future<LocationSnapshot?> getCachedLocation() async {
    final p = await prefs;
    final json = p.getString(_keyLastLocation);
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return LocationSnapshot.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  // TTL
  Future<void> setWeatherTTL(Duration ttl) async {
    final p = await prefs;
    await p.setInt(_keyWeatherTTL, ttl.inSeconds);
  }

  Future<Duration> getWeatherTTL() async {
    final p = await prefs;
    final seconds = p.getInt(_keyWeatherTTL) ?? 300;
    return Duration(seconds: seconds);
  }

  Future<DateTime?> getLastUpdateTime() async {
    final p = await prefs;
    final lastUpdateStr = p.getString(_keyLastUpdate);
    if (lastUpdateStr == null) return null;
    return DateTime.parse(lastUpdateStr);
  }

  // Clear
  Future<void> clearAll() async {
    final p = await prefs;
    await p.remove(_keyLastWeather);
    await p.remove(_keyLastForecast);
    await p.remove(_keyLastLocation);
    await p.remove(_keyLastUpdate);
    await p.remove(_keyWeatherTTL);
  }
}
