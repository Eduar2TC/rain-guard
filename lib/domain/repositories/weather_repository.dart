import '../entities/geo_point.dart';
import '../entities/weather_snapshot.dart';
import '../entities/precipitation_forecast.dart';
import '../enums/network_state.dart';

abstract class WeatherRepository {
  Future<WeatherSnapshot> getCurrentWeather(GeoPoint location);
  Future<PrecipitationForecast> getPrecipitationForecast(GeoPoint location);
  Future<NetworkState> getNetworkState();
  Future<DateTime?> getLastSuccessfulUpdate();
  Future<void> clearCache();
}
