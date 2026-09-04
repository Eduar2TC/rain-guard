import 'package:flutter/material.dart';

import 'package:rain_guard/presentation/screens/home_screen.dart';
import 'package:rain_guard/presentation/screens/settings_screen.dart';
import 'package:rain_guard/presentation/screens/history_screen.dart';
import 'package:rain_guard/presentation/screens/debug_screen.dart';
import 'package:rain_guard/presentation/screens/about_screen.dart';
import 'package:rain_guard/presentation/screens/onboarding_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String settings = '/settings';
  static const String history = '/history';
  static const String debug = '/debug';
  static const String about = '/about';
  static const String onboarding = '/onboarding';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/history':
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case '/debug':
        return MaterialPageRoute(builder: (_) => const DebugScreen());
      case '/about':
        return MaterialPageRoute(builder: (_) => const AboutScreen());
      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
