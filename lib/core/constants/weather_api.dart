class WeatherApiConstants {
  static const String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  static String buildUrl({
    required double latitude,
    required double longitude,
  }) {
    return '$baseUrl'
        '?latitude=$latitude'
        '&longitude=$longitude'
        '&current=precipitation,rain,showers,temperature_2m,'
        'wind_speed_10m,wind_direction_10m,wind_gusts_10m,weather_code'
        '&minutely_15=precipitation'
        '&forecast_days=1'
        '&timezone=auto';
  }
}
