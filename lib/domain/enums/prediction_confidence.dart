enum PredictionConfidence {
  none,
  low,
  medium,
  high;

  String get displayName {
    switch (this) {
      case PredictionConfidence.none:
        return 'Sin confianza';
      case PredictionConfidence.low:
        return 'Confianza baja';
      case PredictionConfidence.medium:
        return 'Confianza media';
      case PredictionConfidence.high:
        return 'Alta confianza';
    }
  }

  static PredictionConfidence fromScore(double score) {
    if (score < 0.40) return PredictionConfidence.none;
    if (score < 0.60) return PredictionConfidence.low;
    if (score < 0.80) return PredictionConfidence.medium;
    return PredictionConfidence.high;
  }
}
