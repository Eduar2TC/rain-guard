enum MovementState {
  stopped,
  slow,
  cycling,
  fast;

  String get displayName {
    switch (this) {
      case MovementState.stopped:
        return 'Detenido';
      case MovementState.slow:
        return 'Movimiento lento';
      case MovementState.cycling:
        return 'Ciclismo';
      case MovementState.fast:
        return 'Movimiento rápido';
    }
  }

  static MovementState fromSpeedKmh(double speedKmh) {
    if (speedKmh < 1) return MovementState.stopped;
    if (speedKmh < 8) return MovementState.slow;
    if (speedKmh < 30) return MovementState.cycling;
    return MovementState.fast;
  }
}
