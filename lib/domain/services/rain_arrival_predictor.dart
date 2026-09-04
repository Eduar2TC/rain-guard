import 'package:rain_guard/domain/entities/location_snapshot.dart';
import 'package:rain_guard/domain/entities/weather_snapshot.dart';
import 'package:rain_guard/domain/entities/precipitation_forecast.dart';
import 'package:rain_guard/domain/entities/rain_arrival_prediction.dart';
import 'package:rain_guard/domain/enums/rain_risk_state.dart';
import 'package:rain_guard/domain/enums/rain_intensity.dart';
import 'package:rain_guard/domain/enums/prediction_confidence.dart';
import 'package:rain_guard/core/constants/alert_thresholds.dart';
import 'precipitation_analyzer.dart';

class RainArrivalPredictor {
  final PrecipitationAnalyzer _analyzer;

  RainArrivalPredictor({PrecipitationAnalyzer? analyzer})
      : _analyzer = analyzer ?? PrecipitationAnalyzer();

  RainArrivalPrediction predict({
    required LocationSnapshot location,
    required WeatherSnapshot weather,
    required PrecipitationForecast forecast,
  }) {
    final analysis = _analyzer.analyze(
      weather: weather,
      forecast: forecast,
    );

    // If currently raining, return immediate state
    if (analysis.isRaining && analysis.currentPrecipitation > AlertThresholds.lightRain) {
      return RainArrivalPrediction(
        state: RainRiskState.raining,
        eta: Duration.zero,
        distanceMeters: 0,
        intensity: analysis.currentIntensity,
        confidence: PredictionConfidence.high,
        source: 'current_observation',
        timestamp: DateTime.now(),
      );
    }

    // Calculate ETA from forecast
    final eta = _calculateEta(
      location: location,
      weather: weather,
      forecast: forecast,
      analysis: analysis,
    );

    // Determine risk state based on ETA
    final state = _determineState(eta, analysis);

    // Calculate distance (approximate)
    final distance = _estimateDistance(eta, weather.windSpeed);

    // Calculate confidence
    final confidence = _calculateConfidence(analysis, eta);

    return RainArrivalPrediction(
      state: state,
      eta: eta,
      distanceMeters: distance,
      intensity: _classifyForecastIntensity(analysis.forecastMaxPrecipitation),
      confidence: confidence,
      direction: _calculateDirection(weather.windDirection),
      source: 'forecast',
      timestamp: DateTime.now(),
    );
  }

  RainIntensity _classifyForecastIntensity(double maxPrecipitation) {
    if (maxPrecipitation >= AlertThresholds.extremeRain) {
      return RainIntensity.extreme;
    } else if (maxPrecipitation >= AlertThresholds.heavyRain) {
      return RainIntensity.heavy;
    } else if (maxPrecipitation >= AlertThresholds.moderateRain) {
      return RainIntensity.moderate;
    } else if (maxPrecipitation >= AlertThresholds.lightRain) {
      return RainIntensity.light;
    }
    return RainIntensity.none;
  }

  Duration? _calculateEta({
    required LocationSnapshot location,
    required WeatherSnapshot weather,
    required PrecipitationForecast forecast,
    required PrecipitationAnalysis analysis,
  }) {
    // If forecast shows rain, use that ETA
    if (analysis.forecastFirstRainEta != null) {
      return analysis.forecastFirstRainEta;
    }

    // If wind is bringing rain, estimate based on wind speed
    if (weather.windSpeed > 0 && analysis.forecastHasRain) {
      // Rough estimation: rain travels at wind speed
      // This is a simplification - real implementation would use radar
      return const Duration(minutes: 30); // Default conservative estimate
    }

    return null;
  }

  RainRiskState _determineState(Duration? eta, PrecipitationAnalysis analysis) {
    if (eta == null) {
      return analysis.hasAnyPrecipitation ? RainRiskState.watch : RainRiskState.idle;
    }

    final minutes = eta.inMinutes;

    if (minutes <= AlertThresholds.imminentThreshold) {
      return RainRiskState.imminent;
    } else if (minutes <= AlertThresholds.warningThreshold) {
      return RainRiskState.warning;
    } else if (minutes <= AlertThresholds.approachingThreshold) {
      return RainRiskState.approaching;
    } else if (minutes <= AlertThresholds.watchThreshold) {
      return RainRiskState.watch;
    } else {
      return RainRiskState.idle;
    }
  }

  double? _estimateDistance(Duration? eta, double windSpeed) {
    if (eta == null || windSpeed <= 0) return null;

    // Rough estimation: rain moves at wind speed
    // windSpeed is in km/h, convert to m/s
    final speedMs = windSpeed / 3.6;
    return speedMs * eta.inSeconds;
  }

  PredictionConfidence _calculateConfidence(
    PrecipitationAnalysis analysis,
    Duration? eta,
  ) {
    double score = analysis.confidence;

    // Reduce confidence for very long ETAs
    if (eta != null && eta.inMinutes > 60) {
      score *= 0.7;
    }

    // Reduce confidence if no forecast data
    if (!analysis.forecastHasRain && !analysis.isRaining) {
      score *= 0.5;
    }

    if (score >= AlertThresholds.highConfidence) {
      return PredictionConfidence.high;
    } else if (score >= AlertThresholds.mediumConfidence) {
      return PredictionConfidence.medium;
    } else if (score >= AlertThresholds.lowConfidence) {
      return PredictionConfidence.low;
    } else {
      return PredictionConfidence.none;
    }
  }

  double? _calculateDirection(double windDirection) {
    // Wind direction indicates where rain is coming FROM
    // We want direction TO the rain (opposite direction)
    return (windDirection + 180) % 360;
  }
}
