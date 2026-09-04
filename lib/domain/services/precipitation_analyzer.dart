import '../entities/weather_snapshot.dart';
import '../entities/precipitation_forecast.dart';
import '../enums/rain_intensity.dart';

class PrecipitationAnalyzer {
  /// Analyze current precipitation conditions
  PrecipitationAnalysis analyze({
    required WeatherSnapshot weather,
    required PrecipitationForecast forecast,
  }) {
    final currentIntensity = _classifyIntensity(weather.precipitation);
    final forecastAnalysis = _analyzeForecast(forecast);

    return PrecipitationAnalysis(
      currentPrecipitation: weather.precipitation,
      currentIntensity: currentIntensity,
      isRaining: weather.isRaining,
      forecastHasRain: forecastAnalysis.hasRain,
      forecastMaxPrecipitation: forecastAnalysis.maxPrecipitation,
      forecastFirstRainEta: forecastAnalysis.firstRainEta,
      windSpeed: weather.windSpeed,
      windDirection: weather.windDirection,
      windGust: weather.windGust,
      confidence: _calculateConfidence(
        weather: weather,
        forecast: forecast,
        forecastAnalysis: forecastAnalysis,
      ),
    );
  }

  RainIntensity _classifyIntensity(double precipitation) {
    return RainIntensity.fromMmPerHour(precipitation);
  }

  _ForecastAnalysis _analyzeForecast(PrecipitationForecast forecast) {
    final now = DateTime.now();
    final intervals = forecast.intervals;

    bool hasRain = false;
    double maxPrecipitation = 0;
    Duration? firstRainEta;

    for (final interval in intervals) {
      if (interval.hasPrecipitation) {
        hasRain = true;
        if (interval.precipitation > maxPrecipitation) {
          maxPrecipitation = interval.precipitation;
        }
        if (firstRainEta == null && interval.time.isAfter(now)) {
          firstRainEta = interval.time.difference(now);
        }
      }
    }

    return _ForecastAnalysis(
      hasRain: hasRain,
      maxPrecipitation: maxPrecipitation,
      firstRainEta: firstRainEta,
    );
  }

  double _calculateConfidence({
    required WeatherSnapshot weather,
    required PrecipitationForecast forecast,
    required _ForecastAnalysis forecastAnalysis,
  }) {
    double confidence = 0.5; // Base confidence

    // Increase confidence if currently raining
    if (weather.isRaining) {
      confidence += 0.3;
    }

    // Increase confidence if forecast shows rain
    if (forecastAnalysis.hasRain) {
      confidence += 0.1;
    }

    // Decrease confidence if data is stale
    if (weather.isStale) {
      confidence -= 0.2;
    }

    // Decrease confidence if very low precipitation
    if (weather.precipitation < 0.1 && !forecastAnalysis.hasRain) {
      confidence -= 0.1;
    }

    return confidence.clamp(0.0, 1.0);
  }
}

class PrecipitationAnalysis {
  final double currentPrecipitation;
  final RainIntensity currentIntensity;
  final bool isRaining;
  final bool forecastHasRain;
  final double forecastMaxPrecipitation;
  final Duration? forecastFirstRainEta;
  final double windSpeed;
  final double windDirection;
  final double windGust;
  final double confidence;

  const PrecipitationAnalysis({
    required this.currentPrecipitation,
    required this.currentIntensity,
    required this.isRaining,
    required this.forecastHasRain,
    required this.forecastMaxPrecipitation,
    this.forecastFirstRainEta,
    required this.windSpeed,
    required this.windDirection,
    required this.windGust,
    required this.confidence,
  });

  bool get hasAnyPrecipitation => isRaining || forecastHasRain;
}

class _ForecastAnalysis {
  final bool hasRain;
  final double maxPrecipitation;
  final Duration? firstRainEta;

  const _ForecastAnalysis({
    required this.hasRain,
    required this.maxPrecipitation,
    this.firstRainEta,
  });
}
