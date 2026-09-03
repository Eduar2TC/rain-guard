class AlertThresholds {
  // ETA thresholds (in minutes)
  static const double watchThreshold = 15.0;
  static const double approachingThreshold = 10.0;
  static const double warningThreshold = 5.0;
  static const double imminentThreshold = 2.0;

  // Precipitation thresholds (mm/h)
  static const double lightRain = 0.5;
  static const double moderateRain = 4.0;
  static const double heavyRain = 10.0;
  static const double extremeRain = 30.0;

  // Confidence thresholds
  static const double highConfidence = 0.80;
  static const double mediumConfidence = 0.60;
  static const double lowConfidence = 0.40;

  // Polling intervals (in seconds)
  static const int normalPolling = 300; // 5 min
  static const int watchPolling = 300; // 5 min
  static const int approachingPolling = 180; // 3 min
  static const int warningPolling = 90; // 1.5 min
  static const int rainingPolling = 180; // 3 min

  // Data freshness (in seconds)
  static const int maxDataAge = 600; // 10 min
  static const int staleDataWarning = 300; // 5 min

  // Hysteresis
  static const int rainConfirmationCycles = 2;
  static const int rainPassCycles = 3;

  // Battery
  static const double lowBatteryThreshold = 15.0;
  static const double criticalBatteryThreshold = 5.0;

  // Location accuracy
  static const double maxAccuracyForAlerts = 200.0; // meters
  static const double optimalAccuracy = 50.0; // meters
}
