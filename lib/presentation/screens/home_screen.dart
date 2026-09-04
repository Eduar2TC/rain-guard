import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rain_guard/application/state/alert_state_provider.dart';
import 'package:rain_guard/application/state/monitoring_service_provider.dart';
import 'package:rain_guard/domain/enums/rain_risk_state.dart';
import 'package:rain_guard/presentation/widgets/location_info.dart';
import 'package:rain_guard/presentation/widgets/weather_summary.dart';
import 'package:rain_guard/presentation/widgets/eta_indicator.dart';
import 'package:rain_guard/presentation/widgets/monitoring_toggle.dart';
import 'package:rain_guard/presentation/widgets/bubble_preview.dart';
import 'package:rain_guard/presentation/widgets/battery_status_card.dart';
import 'debug_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'about_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuTap(context, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Configuración'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'history',
                        child: ListTile(
                          leading: Icon(Icons.history),
                          title: Text('Historial'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'debug',
                        child: ListTile(
                          leading: Icon(Icons.bug_report),
                          title: Text('Debug'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'about',
                        child: ListTile(
                          leading: Icon(Icons.info_outline),
                          title: Text('Acerca de'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Location Info
              const LocationInfo(),
              const SizedBox(height: 16),

              // ETA Indicator (Prediction) - Main focus
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      EtaIndicator(),
                      SizedBox(height: 16),
                      WeatherSummary(),
                      SizedBox(height: 16),
                      BatteryStatusCard(),
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

  void _handleMenuTap(BuildContext context, String value) {
    switch (value) {
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
      case 'history':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        );
        break;
      case 'debug':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DebugScreen()),
        );
        break;
      case 'about':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        );
        break;
    }
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
