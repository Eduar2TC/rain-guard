import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/state/settings_state_provider.dart';
import '../../domain/enums/monitoring_mode.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsStateProvider);

    if (!settings.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          // Monitoring section
          _buildSectionHeader('Monitoreo'),
          SwitchListTile(
            title: const Text('Alertas activadas'),
            subtitle: const Text('Recibir notificaciones de lluvia'),
            value: settings.alertsEnabled,
            onChanged: (value) {
              ref.read(settingsStateProvider.notifier).setAlertsEnabled(value);
            },
          ),
          ListTile(
            title: const Text('Modo de alerta'),
            subtitle: Text(settings.monitoringMode.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMonitoringModeDialog(context, ref, settings),
          ),
          Slider(
            value: settings.pollingInterval,
            min: 1,
            max: 10,
            divisions: 9,
            label: '${settings.pollingInterval.toStringAsFixed(0)} min',
            onChanged: (value) {
              ref.read(settingsStateProvider.notifier).setPollingInterval(value);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Intervalo de actualización: ${settings.pollingInterval.toStringAsFixed(0)} minutos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          const Divider(),

          // Bubble section
          _buildSectionHeader('Burbuja flotante'),
          SwitchListTile(
            title: const Text('Mostrar burbuja'),
            subtitle: const Text('Icono flotante sobre otras apps'),
            value: settings.bubbleEnabled,
            onChanged: (value) {
              ref.read(settingsStateProvider.notifier).setBubbleEnabled(value);
            },
          ),

          const Divider(),

          // Sound section
          _buildSectionHeader('Sonido y vibración'),
          SwitchListTile(
            title: const Text('Sonido'),
            subtitle: const Text('Reproducir sonido en alertas'),
            value: settings.soundEnabled,
            onChanged: (value) {
              ref.read(settingsStateProvider.notifier).setSoundEnabled(value);
            },
          ),
          SwitchListTile(
            title: const Text('Vibración'),
            subtitle: const Text('Vibrar en alertas'),
            value: settings.vibrationEnabled,
            onChanged: (value) {
              ref.read(settingsStateProvider.notifier).setVibrationEnabled(value);
            },
          ),

          const Divider(),

          // About section
          _buildSectionHeader('Acerca de'),
          const ListTile(
            title: Text('Versión'),
            subtitle: Text('1.0.0 MVP'),
          ),
          const ListTile(
            title: Text('Datos meteorológicos'),
            subtitle: Text('Open-Meteo (gratuito)'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  void _showMonitoringModeDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modo de alerta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<MonitoringMode>(
              groupValue: settings.monitoringMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsStateProvider.notifier).setMonitoringMode(value);
                  Navigator.pop(context);
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: MonitoringMode.values.map((mode) {
                  return RadioListTile<MonitoringMode>(
                    title: Text(mode.displayName),
                    value: mode,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
