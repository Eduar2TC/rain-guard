enum RainRiskState {
  idle,
  watch,
  approaching,
  warning,
  imminent,
  raining,
  passed,
  unknown;

  String get displayName {
    switch (this) {
      case RainRiskState.idle:
        return 'Sin lluvia cercana';
      case RainRiskState.watch:
        return 'Posible lluvia';
      case RainRiskState.approaching:
        return 'Lluvia acercándose';
      case RainRiskState.warning:
        return 'Prepárate';
      case RainRiskState.imminent:
        return 'Lluvia inminente';
      case RainRiskState.raining:
        return 'Está lloviendo';
      case RainRiskState.passed:
        return 'Lluvia pasó';
      case RainRiskState.unknown:
        return 'Sin datos';
    }
  }

  String get emoji {
    switch (this) {
      case RainRiskState.idle:
        return '☀️';
      case RainRiskState.watch:
        return '🌦️';
      case RainRiskState.approaching:
        return '🌧️';
      case RainRiskState.warning:
        return '⚠️';
      case RainRiskState.imminent:
        return '🚨';
      case RainRiskState.raining:
        return '🌧️';
      case RainRiskState.passed:
        return '✓';
      case RainRiskState.unknown:
        return '?';
    }
  }

  static RainRiskState fromString(String value) {
    return RainRiskState.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RainRiskState.unknown,
    );
  }
}
