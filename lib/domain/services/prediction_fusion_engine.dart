import '../../entities/location_snapshot.dart';
import '../../entities/weather_snapshot.dart';
import '../../entities/precipitation_forecast.dart';
import '../../entities/rain_arrival_prediction.dart';
import '../../enums/rain_risk_state.dart';
import '../../enums/prediction_confidence.dart';
import 'rain_arrival_predictor.dart';

/// Combines multiple prediction sources to produce a final prediction
class PredictionFusionEngine {
  final RainArrivalPredictor _weatherPredictor;

  PredictionFusionEngine({
    RainArrivalPredictor? weatherPredictor,
  }) : _weatherPredictor = weatherPredictor ?? RainArrivalPredictor();

  /// Fuse predictions from multiple sources
  /// Currently only uses weather forecast, but designed for future radar integration
  RainArrivalPrediction fuse({
    required LocationSnapshot location,
    required WeatherSnapshot weather,
    required PrecipitationForecast forecast,
    RainArrivalPrediction? radarPrediction,
  }) {
    // Get weather-based prediction
    final weatherPrediction = _weatherPredictor.predict(
      location: location,
      weather: weather,
      forecast: forecast,
    );

    // If no radar prediction, use weather only
    if (radarPrediction == null) {
      return weatherPrediction;
    }

    // Fuse predictions based on confidence weights
    return _fusePredictions(
      weather: weatherPrediction,
      radar: radarPrediction,
    );
  }

  RainArrivalPrediction _fusePredictions({
    required RainArrivalPrediction weather,
    required RainArrivalPrediction radar,
  }) {
    // For now, use simple weighted average based on confidence
    // In the future, this could use more sophisticated fusion

    final weatherWeight = _getConfidenceWeight(weather.confidence);
    final radarWeight = _getConfidenceWeight(radar.confidence);

    final totalWeight = weatherWeight + radarWeight;
    if (totalWeight == 0) {
      return weather; // Fallback to weather prediction
    }

    // Choose the more conservative (earlier) prediction
    // This is safer for cyclist safety
    if (weather.eta != null && radar.eta != null) {
      final earlierEta = weather.eta! < radar.eta! ? weather : radar;
      final laterEta = weather.eta! < radar.eta! ? radar : weather;

      // If predictions are close (within 5 minutes), use the earlier one
      final difference = (weather.eta! - radar.eta!).abs();
      if (difference.inMinutes <= 5) {
        return earlierEta.copyWith(
          confidence: _blendConfidences(weather.confidence, radar.confidence),
          source: 'fused',
        );
      }

      // If predictions differ significantly, use radar for short-term
      // and weather for longer-term
      if (radar.eta!.inMinutes <= 15) {
        return radar.copyWith(
          confidence: _blendConfidences(weather.confidence, radar.confidence),
          source: 'fused_radar_priority',
        );
      }
    }

    // Default: use weather prediction with blended confidence
    return weather.copyWith(
      confidence: _blendConfidences(weather.confidence, radar.confidence),
      source: 'fused',
    );
  }

  double _getConfidenceWeight(PredictionConfidence confidence) {
    switch (confidence) {
      case PredictionConfidence.high:
        return 1.0;
      case PredictionConfidence.medium:
        return 0.7;
      case PredictionConfidence.low:
        return 0.4;
      case PredictionConfidence.none:
        return 0.1;
    }
  }

  PredictionConfidence _blendConfidences(
    PredictionConfidence a,
    PredictionConfidence b,
  ) {
    final scoreA = _confidenceToScore(a);
    final scoreB = _confidenceToScore(b);
    final blended = (scoreA + scoreB) / 2;

    if (blended >= 0.8) return PredictionConfidence.high;
    if (blended >= 0.6) return PredictionConfidence.medium;
    if (blended >= 0.4) return PredictionConfidence.low;
    return PredictionConfidence.none;
  }

  double _confidenceToScore(PredictionConfidence confidence) {
    switch (confidence) {
      case PredictionConfidence.high:
        return 0.9;
      case PredictionConfidence.medium:
        return 0.7;
      case PredictionConfidence.low:
        return 0.5;
      case PredictionConfidence.none:
        return 0.2;
    }
  }
}
