enum AlertPriority {
  low,
  normal,
  high,
  critical;

  int get androidPriority {
    switch (this) {
      case AlertPriority.low:
        return 1; // PRIORITY_LOW
      case AlertPriority.normal:
        return 2; // PRIORITY_DEFAULT
      case AlertPriority.high:
        return 3; // PRIORITY_HIGH
      case AlertPriority.critical:
        return 4; // PRIORITY_MAX
    }
  }
}
