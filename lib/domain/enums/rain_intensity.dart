enum RainIntensity {
  none,
  light,
  moderate,
  heavy,
  extreme;

  String get displayName {
    switch (this) {
      case RainIntensity.none:
        return 'Sin lluvia';
      case RainIntensity.light:
        return 'Lluvia ligera';
      case RainIntensity.moderate:
        return 'Lluvia moderada';
      case RainIntensity.heavy:
        return 'Lluvia intensa';
      case RainIntensity.extreme:
        return 'Lluvia extrema';
    }
  }

  static RainIntensity fromMmPerHour(double mm) {
    if (mm < 0.5) return RainIntensity.none;
    if (mm < 4.0) return RainIntensity.light;
    if (mm < 10.0) return RainIntensity.moderate;
    if (mm < 30.0) return RainIntensity.heavy;
    return RainIntensity.extreme;
  }
}
