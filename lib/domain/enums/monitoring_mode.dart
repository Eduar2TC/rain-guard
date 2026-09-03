enum MonitoringMode {
  quiet,
  vibration,
  sound,
  full;

  String get displayName {
    switch (this) {
      case MonitoringMode.quiet:
        return 'Silencioso';
      case MonitoringMode.vibration:
        return 'Vibración';
      case MonitoringMode.sound:
        return 'Sonido';
      case MonitoringMode.full:
        return 'Completo';
    }
  }

  bool get shouldVibrate =>
      this == MonitoringMode.vibration || this == MonitoringMode.full;

  bool get shouldPlaySound =>
      this == MonitoringMode.sound || this == MonitoringMode.full;
}
