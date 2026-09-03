class WeatherSnapshot {
  final DateTime timestamp;
  final DateTime sourceTimestamp;
  final double precipitation;
  final double rain;
  final double showers;
  final double temperature;
  final double windSpeed;
  final double windDirection;
  final double windGust;
  final int weatherCode;

  const WeatherSnapshot({
    required this.timestamp,
    required this.sourceTimestamp,
    required this.precipitation,
    required this.rain,
    required this.showers,
    required this.temperature,
    required this.windSpeed,
    required this.windDirection,
    required this.windGust,
    required this.weatherCode,
  });

  bool get isRaining => precipitation > 0.1 || rain > 0.1;

  Duration get dataAge => DateTime.now().difference(timestamp);

  bool get isStale => dataAge.inSeconds > 600; // 10 minutes

  WeatherSnapshot copyWith({
    DateTime? timestamp,
    DateTime? sourceTimestamp,
    double? precipitation,
    double? rain,
    double? showers,
    double? temperature,
    double? windSpeed,
    double? windDirection,
    double? windGust,
    int? weatherCode,
  }) {
    return WeatherSnapshot(
      timestamp: timestamp ?? this.timestamp,
      sourceTimestamp: sourceTimestamp ?? this.sourceTimestamp,
      precipitation: precipitation ?? this.precipitation,
      rain: rain ?? this.rain,
      showers: showers ?? this.showers,
      temperature: temperature ?? this.temperature,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      windGust: windGust ?? this.windGust,
      weatherCode: weatherCode ?? this.weatherCode,
    );
  }

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'sourceTimestamp': sourceTimestamp.toIso8601String(),
        'precipitation': precipitation,
        'rain': rain,
        'showers': showers,
        'temperature': temperature,
        'windSpeed': windSpeed,
        'windDirection': windDirection,
        'windGust': windGust,
        'weatherCode': weatherCode,
      };

  factory WeatherSnapshot.fromMap(Map<String, dynamic> map) =>
      WeatherSnapshot(
        timestamp: DateTime.parse(map['timestamp']),
        sourceTimestamp: DateTime.parse(map['sourceTimestamp']),
        precipitation: (map['precipitation'] as num).toDouble(),
        rain: (map['rain'] as num).toDouble(),
        showers: (map['showers'] as num).toDouble(),
        temperature: (map['temperature'] as num).toDouble(),
        windSpeed: (map['windSpeed'] as num).toDouble(),
        windDirection: (map['windDirection'] as num).toDouble(),
        windGust: (map['windGust'] as num).toDouble(),
        weatherCode: map['weatherCode'] as int,
      );
}
