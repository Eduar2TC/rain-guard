import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rain_guard/application/state/location_state_provider.dart';

class LocationInfo extends ConsumerWidget {
  const LocationInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationStateProvider);
    void onRequestPermission() =>
        ref.read(locationStateProvider.notifier).requestPermission();

    if (locationState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Obteniendo ubicación...'),
            ],
          ),
        ),
      );
    }

    if (!locationState.hasPermission) {
      return Card(
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.location_off, color: Colors.orange, size: 32),
              const SizedBox(height: 8),
              const Text(
                'Permiso de ubicación requerido',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'RainGuard necesita tu ubicación para saber dónde estás.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: onRequestPermission,
                child: const Text('Conceder permiso'),
              ),
            ],
          ),
        ),
      );
    }

    final location = locationState.currentLocation;
    if (location == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.location_searching, color: Colors.grey),
              SizedBox(width: 16),
              Text('Esperando ubicación...'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Ubicación activa',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${location.position.latitude.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Lon: ${location.position.longitude.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Velocidad: ${location.speedKmh.toStringAsFixed(1)} km/h',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Precisión: ${location.accuracy.toStringAsFixed(1)} m',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
