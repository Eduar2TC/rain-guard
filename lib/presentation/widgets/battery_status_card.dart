import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/state/battery_state_provider.dart';

class BatteryStatusCard extends ConsumerWidget {
  const BatteryStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryState = ref.watch(batteryStateProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getBatteryIcon(batteryState),
                  color: _getBatteryColor(batteryState),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Batería',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  batteryState.statusText,
                  style: TextStyle(
                    color: _getBatteryColor(batteryState),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Battery level bar
            LinearProgressIndicator(
              value: batteryState.percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getBatteryColor(batteryState),
              ),
            ),
            const SizedBox(height: 8),

            // Battery info
            if (batteryState.isCharging)
              Text(
                'Cargando via ${batteryState.chargingSource}',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),

            if (batteryState.isPowerSaveMode)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Modo ahorro de batería activo',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                ),
              ),

            if (!batteryState.isIgnoringBatteryOptimizations)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RainGuard puede ser restringido por el sistema',
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(batteryStateProvider.notifier).requestIgnoreBatteryOptimizations();
                        },
                        icon: const Icon(Icons.battery_saver, size: 16),
                        label: const Text('Desactivar restricciones'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getBatteryIcon(BatteryState state) {
    if (state.isCharging) {
      return Icons.battery_charging_full;
    }
    if (state.percentage > 80) {
      return Icons.battery_full;
    } else if (state.percentage > 50) {
      return Icons.battery_5_bar;
    } else if (state.percentage > 20) {
      return Icons.battery_3_bar;
    } else if (state.percentage > 10) {
      return Icons.battery_2_bar;
    } else {
      return Icons.battery_alert;
    }
  }

  Color _getBatteryColor(BatteryState state) {
    if (state.isCharging) {
      return Colors.green;
    }
    if (state.isCriticalBattery) {
      return Colors.red;
    }
    if (state.isLowBattery) {
      return Colors.orange;
    }
    return Colors.green;
  }
}
