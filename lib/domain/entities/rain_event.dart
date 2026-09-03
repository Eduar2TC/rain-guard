import '../enums/prediction_confidence.dart';
import '../enums/rain_intensity.dart';
import 'geo_point.dart';

class RainEvent {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final GeoPoint? location;
  final RainIntensity maxIntensity;
  final Duration? predictedEta;
  final PredictionConfidence predictionConfidence;
  final bool? actualRainDetected;
  final double? predictedEtaMinutes;
  final double? actualDurationMinutes;

  const RainEvent({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.location,
    required this.maxIntensity,
    this.predictedEta,
    this.predictionConfidence = PredictionConfidence.none,
    this.actualRainDetected,
    this.predictedEtaMinutes,
    this.actualDurationMinutes,
  });

  bool get isActive => endedAt == null;

  Duration? get duration {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt);
  }

  double? get predictionError {
    if (predictedEtaMinutes == null || actualDurationMinutes == null) {
      return null;
    }
    return actualDurationMinutes! - predictedEtaMinutes!;
  }

  RainEvent copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    GeoPoint? location,
    RainIntensity? maxIntensity,
    Duration? predictedEta,
    PredictionConfidence? predictionConfidence,
    bool? actualRainDetected,
    double? predictedEtaMinutes,
    double? actualDurationMinutes,
  }) {
    return RainEvent(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      location: location ?? this.location,
      maxIntensity: maxIntensity ?? this.maxIntensity,
      predictedEta: predictedEta ?? this.predictedEta,
      predictionConfidence: predictionConfidence ?? this.predictionConfidence,
      actualRainDetected: actualRainDetected ?? this.actualRainDetected,
      predictedEtaMinutes: predictedEtaMinutes ?? this.predictedEtaMinutes,
      actualDurationMinutes: actualDurationMinutes ?? this.actualDurationMinutes,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'location': location?.toMap(),
        'maxIntensity': maxIntensity.name,
        'predictedEtaMinutes': predictedEta?.inMinutes,
        'predictionConfidence': predictionConfidence.name,
        'actualRainDetected': actualRainDetected,
        'predictedEtaMinutesValue': predictedEtaMinutes,
        'actualDurationMinutes': actualDurationMinutes,
      };

  factory RainEvent.fromMap(Map<String, dynamic> map) => RainEvent(
        id: map['id'] as String,
        startedAt: DateTime.parse(map['startedAt']),
        endedAt: map['endedAt'] != null ? DateTime.parse(map['endedAt']) : null,
        location:
            map['location'] != null ? GeoPoint.fromMap(map['location']) : null,
        maxIntensity: RainIntensity.values.firstWhere(
          (e) => e.name == map['maxIntensity'],
          orElse: () => RainIntensity.none,
        ),
        predictedEta: map['predictedEtaMinutes'] != null
            ? Duration(minutes: map['predictedEtaMinutes'] as int)
            : null,
        predictionConfidence: PredictionConfidence.values.firstWhere(
          (e) => e.name == map['predictionConfidence'],
          orElse: () => PredictionConfidence.none,
        ),
        actualRainDetected: map['actualRainDetected'] as bool?,
        predictedEtaMinutes: (map['predictedEtaMinutesValue'] as num?)?.toDouble(),
        actualDurationMinutes: (map['actualDurationMinutes'] as num?)?.toDouble(),
      );
}
