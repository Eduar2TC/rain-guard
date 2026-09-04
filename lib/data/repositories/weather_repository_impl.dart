import '../../domain/entities/geo_point.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/entities/precipitation_forecast.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../domain/enums/network_state.dart';
import '../datasources/weather_data_source.dart';
import '../datasources/local_storage_data_source.dart';
import '../datasources/network_data_source.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherDataSource _weatherDataSource;
  final LocalStorageDataSource _localStorage;
  final NetworkDataSource _networkDataSource;

  // Cache the last fetched JSON to avoid duplicate API calls
  Map<String, dynamic>? _lastFetchJson;
  GeoPoint? _lastFetchLocation;

  WeatherRepositoryImpl({
    required WeatherDataSource weatherDataSource,
    required LocalStorageDataSource localStorage,
    required NetworkDataSource networkDataSource,
  })  : _weatherDataSource = weatherDataSource,
        _localStorage = localStorage,
        _networkDataSource = networkDataSource;

  @override
  Future<WeatherSnapshot> getCurrentWeather(GeoPoint location) async {
    // Try to fetch fresh data if network is available
    if (_networkDataSource.isConnected) {
      final jsonData = await _fetchWeatherData(location);
      if (jsonData != null) {
        final weather = _weatherDataSource.parseWeatherSnapshot(jsonData);
        if (weather != null) {
          await _localStorage.cacheWeather(weather);
          return weather;
        }
      }
    }

    // Fallback to cached data
    final cached = await _localStorage.getCachedWeather();
    if (cached != null) {
      return cached;
    }

    // Return default if nothing available
    return WeatherSnapshot(
      timestamp: DateTime.now(),
      sourceTimestamp: DateTime.now(),
      precipitation: 0,
      rain: 0,
      showers: 0,
      temperature: 0,
      windSpeed: 0,
      windDirection: 0,
      windGust: 0,
      weatherCode: 0,
    );
  }

  @override
  Future<PrecipitationForecast> getPrecipitationForecast(GeoPoint location) async {
    if (_networkDataSource.isConnected) {
      final jsonData = await _fetchWeatherData(location);
      if (jsonData != null) {
        final forecast = _weatherDataSource.parsePrecipitationForecast(jsonData);
        if (forecast != null) {
          await _localStorage.cacheForecast(forecast);
          return forecast;
        }
      }
    }

    final cached = await _localStorage.getCachedForecast();
    if (cached != null) {
      return cached;
    }

    return PrecipitationForecast(
      timestamp: DateTime.now(),
      intervals: [],
    );
  }

  /// Fetch weather data once, reusing the cached result for the same location
  Future<Map<String, dynamic>?> _fetchWeatherData(GeoPoint location) async {
    if (_lastFetchJson != null && _lastFetchLocation == location) {
      return _lastFetchJson;
    }
    final jsonData = await _weatherDataSource.fetchWeatherData(location);
    if (jsonData != null) {
      _lastFetchJson = jsonData;
      _lastFetchLocation = location;
    }
    return jsonData;
  }

  @override
  Future<NetworkState> getNetworkState() async {
    switch (_networkDataSource.currentType) {
      case NetworkType.wifi:
        return NetworkState.wifi;
      case NetworkType.mobile:
        return NetworkState.mobile;
      case NetworkType.noConnection:
        return NetworkState.noConnection;
    }
  }

  @override
  Future<DateTime?> getLastSuccessfulUpdate() async {
    return _localStorage.getLastUpdateTime();
  }

  @override
  Future<void> clearCache() async {
    await _localStorage.clearAll();
  }
}
