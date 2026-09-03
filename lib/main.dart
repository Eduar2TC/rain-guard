import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'presentation/screens/home_screen.dart';
import 'presentation/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

  runApp(
    ProviderScope(
      child: RainGuardApp(onboardingComplete: onboardingComplete),
    ),
  );
}

class RainGuardApp extends StatelessWidget {
  final bool onboardingComplete;

  const RainGuardApp({super.key, required this.onboardingComplete});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RainGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: onboardingComplete ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
