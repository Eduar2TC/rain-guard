import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../application/state/bubble_state_provider.dart';
import '../../application/state/alert_state_provider.dart';
import '../../domain/enums/monitoring_mode.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _bubbleEnabled = true;
  MonitoringMode _monitoringMode = MonitoringMode.full;
  bool _alertsEnabled = true;
  double _pollingInterval = 5.0;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bubbleEnabled = prefs.getBool('bubble_enabled') ?? true;
      _monitoringMode = MonitoringMode.values[prefs.getInt('monitoring_mode') ?? 3];
      _alertsEnabled = prefs.getBool('alerts_enabled') ?? true;
      _pollingInterval = prefs.getDouble('polling_interval') ?? 5.0;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            value: _alertsEnabled,
            onChanged: (value) {
              setState(() {
                _alertsEnabled = value;
              });
              _saveSetting('alerts_enabled', value);
              ref.read(alertStateProvider.notifier).toggleAlerts();
            },
          ),
          ListTile(
            title: const Text('Modo de alerta'),
            subtitle: Text(_monitoringMode.displayName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMonitoringModeDialog(),
          ),
          Slider(
            value: _pollingInterval,
            min: 1,
            max: 10,
            divisions: 9,
            label: '${_pollingInterval.toStringAsFixed(0)} min',
            onChanged: (value) {
              setState(() {
                _pollingInterval = value;
              });
              _saveSetting('polling_interval', value);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Intervalo de actualización: ${_pollingInterval.toStringAsFixed(0)} minutos',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          const Divider(),

          // Bubble section
          _buildSectionHeader('Burbuja flotante'),
          SwitchListTile(
            title: const Text('Mostrar burbuja'),
            subtitle: const Text('Icono flotante sobre otras apps'),
            value: _bubbleEnabled,
            onChanged: (value) {
              setState(() {
                _bubbleEnabled = value;
              });
              _saveSetting('bubble_enabled', value);
              if (value) {
                ref.read(bubbleStateProvider.notifier).show();
              } else {
                ref.read(bubbleStateProvider.notifier).hide();
              }
            },
          ),

          const Divider(),

          // Sound section
          _buildSectionHeader('Sonido y vibración'),
          SwitchListTile(
            title: const Text('Sonido'),
            subtitle: const Text('Reproducir sonido en alertas'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
              _saveSetting('sound_enabled', value);
            },
          ),
          SwitchListTile(
            title: const Text('Vibración'),
            subtitle: const Text('Vibrar en alertas'),
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
              _saveSetting('vibration_enabled', value);
            },
          ),

          const Divider(),

          // About section
          _buildSectionHeader('Acerca de'),
          ListTile(
            title: const Text('Versión'),
            subtitle: const Text('1.0.0 MVP'),
          ),
          ListTile(
            title: const Text('Datos meteorológicos'),
            subtitle: const Text('Open-Meteo (gratuito)'),
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
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _showMonitoringModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modo de alerta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: MonitoringMode.values.map((mode) {
            return RadioListTile<MonitoringMode>(
              title: Text(mode.displayName),
              value: mode,
              groupValue: _monitoringMode,
              onChanged: (value) {
                setState(() {
                  _monitoringMode = value!;
                });
                _saveSetting('monitoring_mode', value!.index);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
