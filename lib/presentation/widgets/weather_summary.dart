import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rain_guard/application/state/weather_state_provider.dart';

class WeatherSummary extends ConsumerWidget {
  const WeatherSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherState = ref.watch(weatherStateProvider);

    if (weatherState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Actualizando clima...'),
            ],
          ),
        ),
      );
    }

    if (weatherState.error != null) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error al obtener datos',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      weatherState.error!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final weather = weatherState.currentWeather;
    if (weather == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Sin datos meteorológicos'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  weather.isRaining ? Icons.cloud : Icons.wb_sunny,
                  color: weather.isRaining ? Colors.blue : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  weather.isRaining ? 'Lluvia detectada' : 'Sin lluvia',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: weather.isRaining ? Colors.blue : Colors.green,
                  ),
                ),
                const Spacer(),
                if (weatherState.isDataStale)
                  const Chip(
                    label: Text('Desactualizado', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.orange,
                    labelStyle: TextStyle(color: Colors.white),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Precipitación', '${weather.precipitation.toStringAsFixed(1)} mm'),
            _buildInfoRow('Temperatura', '${weather.temperature.toStringAsFixed(1)}°C'),
            _buildInfoRow('Viento', '${weather.windSpeed.toStringAsFixed(1)} km/h'),
            _buildInfoRow('Ráfagas', '${weather.windGust.toStringAsFixed(1)} km/h'),
            const SizedBox(height: 8),
            Text(
              'Última actualización: ${_formatTime(weatherState.lastUpdate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
