import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/rain_arrival_prediction.dart';
import '../../domain/entities/location_snapshot.dart';
import '../../domain/entities/weather_snapshot.dart';
import '../../domain/entities/precipitation_forecast.dart';
import '../../domain/enums/rain_risk_state.dart';
import '../../domain/enums/prediction_confidence.dart';
import '../../domain/services/rain_arrival_predictor.dart';
import '../../domain/services/prediction_fusion_engine.dart';
import '../../domain/services/precipitation_analyzer.dart';

// Provider for PrecipitationAnalyzer
final precipitationAnalyzerProvider = Provider<PrecipitationAnalyzer>((ref) {
  return PrecipitationAnalyzer();
});

// Provider for RainArrivalPredictor
final rainArrivalPredictorProvider = Provider<RainArrivalPredictor>((ref) {
  final analyzer = ref.watch(precipitationAnalyzerProvider);
  return RainArrivalPredictor(analyzer: analyzer);
});

// Provider for PredictionFusionEngine
final predictionFusionEngineProvider = Provider<PredictionFusionEngine>((ref) {
  final predictor = ref.watch(rainArrivalPredictorProvider);
  return PredictionFusionEngine(weatherPredictor: predictor);
});

// Prediction State
class PredictionState {
  final RainArrivalPrediction? prediction;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdate;

  const PredictionState({
    this.prediction,
    this.isLoading = false,
    this.error,
    this.lastUpdate,
  });

  RainRiskState get riskState => prediction?.state ?? RainRiskState.unknown;

  Duration? get eta => prediction?.eta;

  int? get etaMinutes => prediction?.etaMinutes;

  PredictionConfidence get confidence => prediction?.confidence ?? PredictionConfidence.none;

  bool get hasValidPrediction => prediction != null && prediction!.hasValidEta;

  String get etaDisplay => prediction?.etaDisplay ?? '--';

  String get confidenceDisplay => prediction?.confidence.displayName ?? 'Sin datos';

  String get sourceDisplay {
    switch (prediction?.source) {
      case 'current_observation':
        return 'Observación actual';
      case 'forecast':
        return 'Pronóstico';
      case 'radar':
        return 'Radar';
      case 'fused':
        return 'Combinado';
      default:
        return 'Desconocido';
    }
  }

  PredictionState copyWith({
    RainArrivalPrediction? prediction,
    bool? isLoading,
    String? error,
    DateTime? lastUpdate,
  }) {
    return PredictionState(
      prediction: prediction ?? this.prediction,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

// Prediction State Notifier
class PredictionStateNotifier extends StateNotifier<PredictionState> {
  final PredictionFusionEngine _fusionEngine;

  PredictionStateNotifier(this._fusionEngine) : super(const PredictionState());

  void updatePrediction({
    required LocationSnapshot location,
    required WeatherSnapshot weather,
    required PrecipitationForecast forecast,
  }) {
    try {
      final prediction = _fusionEngine.fuse(
        location: location,
        weather: weather,
        forecast: forecast,
      );

      state = state.copyWith(
        prediction: prediction,
        lastUpdate: DateTime.now(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
      );
    }
  }
}

// Provider
final predictionStateProvider = StateNotifierProvider<PredictionStateNotifier, PredictionState>((ref) {
  final fusionEngine = ref.watch(predictionFusionEngineProvider);
  return PredictionStateNotifier(fusionEngine);
});
