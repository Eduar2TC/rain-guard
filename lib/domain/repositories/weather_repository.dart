import 'package:rain_guard/domain/entities/geo_point.dart';
import 'package:rain_guard/domain/entities/weather_snapshot.dart';
import 'package:rain_guard/domain/entities/precipitation_forecast.dart';
import 'package:rain_guard/domain/enums/network_state.dart';

abstract class WeatherRepository {
  Future<WeatherSnapshot> getCurrentWeather(GeoPoint location);
  Future<PrecipitationForecast> getPrecipitationForecast(GeoPoint location);
  Future<NetworkState> getNetworkState();
  Future<DateTime?> getLastSuccessfulUpdate();
  Future<void> clearCache();
}
