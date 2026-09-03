import 'package:flutter/material.dart';

class AppColors {
  static const Color safe = Color(0xFF4CAF50);
  static const Color watch = Color(0xFFFFC107);
  static const Color approaching = Color(0xFFFF9800);
  static const Color warning = Color(0xFFFF5722);
  static const Color imminent = Color(0xFFF44336);
  static const Color raining = Color(0xFF2196F3);
  static const Color unknown = Color(0xFF9E9E9E);
  static const Color passed = Color(0xFF4CAF50);

  static Color getColorForState(String state) {
    switch (state) {
      case 'idle':
        return safe;
      case 'watch':
        return watch;
      case 'approaching':
        return approaching;
      case 'warning':
        return warning;
      case 'imminent':
        return imminent;
      case 'raining':
        return raining;
      case 'passed':
        return passed;
      default:
        return unknown;
    }
  }
}
