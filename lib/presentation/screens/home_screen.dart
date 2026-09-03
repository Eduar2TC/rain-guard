import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/state/location_state_provider.dart';
import '../../application/state/weather_state_provider.dart';
import '../../application/state/prediction_state_provider.dart';
import '../../application/state/alert_state_provider.dart';
import '../../application/state/monitoring_service_provider.dart';
import '../../domain/enums/rain_risk_state.dart';
import '../widgets/location_info.dart';
import '../widgets/weather_summary.dart';
import '../widgets/eta_indicator.dart';
import '../widgets/monitoring_toggle.dart';
import '../widgets/bubble_preview.dart';
import '../widgets/battery_status_card.dart';
import 'debug_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationStateProvider);
    final weatherState = ref.watch(weatherStateProvider);
    final predictionState = ref.watch(predictionStateProvider);
    final alertState = ref.watch(alertStateProvider);
    final monitoringState = ref.watch(monitoringServiceProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RainGuard',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Row(
                    children: [
                      // Debug button (hidden in release)
                      IconButton(
                        icon: const Icon(Icons.bug_report, size: 20),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DebugScreen(),
                            ),
                          );
                        },
                        tooltip: 'Debug',
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () {
                          // TODO: Navigate to settings
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Location Info
              LocationInfo(
                locationState: locationState,
                onRequestPermission: () {
                  ref.read(locationStateProvider.notifier).requestPermission();
                },
              ),
              const SizedBox(height: 16),

              // ETA Indicator (Prediction) - Main focus
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      EtaIndicator(predictionState: predictionState),
                      const SizedBox(height: 16),
                      WeatherSummary(weatherState: weatherState),
                      const SizedBox(height: 16),
                      const BatteryStatusCard(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Alert state indicator
              if (alertState.currentState != RainRiskState.idle)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    color: _getAlertColor(alertState.currentState),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text(
                            alertState.currentState.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              alertState.lastDecision?.message ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Monitoring Toggle
              MonitoringToggle(
                isActive: monitoringState.isMonitoring,
                isPaused: monitoringState.isPaused,
                onToggle: () {
                  if (monitoringState.isMonitoring) {
                    ref.read(monitoringServiceProvider.notifier).stopMonitoring();
                  } else {
                    ref.read(monitoringServiceProvider.notifier).startMonitoring();
                  }
                },
                onPause: monitoringState.isMonitoring
                    ? () {
                        if (monitoringState.isPaused) {
                          ref.read(monitoringServiceProvider.notifier).resumeMonitoring();
                        } else {
                          ref.read(monitoringServiceProvider.notifier).pauseMonitoring();
                        }
                      }
                    : null,
              ),

              const SizedBox(height: 16),

              // Bubble Toggle
              const BubblePreview(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAlertColor(RainRiskState state) {
    switch (state) {
      case RainRiskState.watch:
        return Colors.amber;
      case RainRiskState.approaching:
        return Colors.orange;
      case RainRiskState.warning:
        return Colors.deepOrange;
      case RainRiskState.imminent:
        return Colors.red;
      case RainRiskState.raining:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
