import '../enums/prediction_confidence.dart';
import '../enums/rain_intensity.dart';
import '../enums/rain_risk_state.dart';

class RainArrivalPrediction {
  final RainRiskState state;
  final Duration? eta;
  final double? distanceMeters;
  final RainIntensity intensity;
  final PredictionConfidence confidence;
  final double? direction;
  final String source;
  final DateTime timestamp;

  const RainArrivalPrediction({
    required this.state,
    this.eta,
    this.distanceMeters,
    required this.intensity,
    required this.confidence,
    this.direction,
    required this.source,
    required this.timestamp,
  });

  int? get etaMinutes => eta?.inMinutes;

  bool get hasValidEta => eta != null && eta!.inSeconds >= 0;

  String get etaDisplay {
    if (!hasValidEta) return '--';
    final minutes = eta!.inMinutes;
    if (minutes == 0) return 'NOW';
    return '~$minutes min';
  }

  String get directionDisplay {
    if (direction == null) return '';
    final dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((direction! + 22.5) % 360 / 45).floor();
    return dirs[index % 8];
  }

  RainArrivalPrediction copyWith({
    RainRiskState? state,
    Duration? eta,
    double? distanceMeters,
    RainIntensity? intensity,
    PredictionConfidence? confidence,
    double? direction,
    String? source,
    DateTime? timestamp,
  }) {
    return RainArrivalPrediction(
      state: state ?? this.state,
      eta: eta ?? this.eta,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      intensity: intensity ?? this.intensity,
      confidence: confidence ?? this.confidence,
      direction: direction ?? this.direction,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
        'state': state.name,
        'etaMinutes': etaMinutes,
        'distanceMeters': distanceMeters,
        'intensity': intensity.name,
        'confidence': confidence.name,
        'direction': direction,
        'source': source,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RainArrivalPrediction.fromMap(Map<String, dynamic> map) =>
      RainArrivalPrediction(
        state: RainRiskState.fromString(map['state']),
        eta: map['etaMinutes'] != null
            ? Duration(minutes: map['etaMinutes'] as int)
            : null,
        distanceMeters: (map['distanceMeters'] as num?)?.toDouble(),
        intensity: RainIntensity.values.firstWhere(
          (e) => e.name == map['intensity'],
          orElse: () => RainIntensity.none,
        ),
        confidence: PredictionConfidence.values.firstWhere(
          (e) => e.name == map['confidence'],
          orElse: () => PredictionConfidence.none,
        ),
        direction: (map['direction'] as num?)?.toDouble(),
        source: map['source'] as String,
        timestamp: DateTime.parse(map['timestamp']),
      );
}
