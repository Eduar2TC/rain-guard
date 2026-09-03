import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App icon
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.water_drop,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // App name
          const Center(
            child: Text(
              'RainGuard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Version
          Center(
            child: Text(
              'Versión 1.0.0 MVP',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RainGuard es un sistema de alerta de lluvia diseñado para ciclistas. '
                    'Detecta la aproximación de lluvia y te avisa con anticipación para que puedas buscar refugio.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Características',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFeature(Icons.location_on, 'Ubicación en tiempo real'),
                  _buildFeature(Icons.cloud, 'Datos meteorológicos de Open-Meteo'),
                  _buildFeature(Icons.timer, 'ETA aproximado de lluvia'),
                  _buildFeature(Icons.notifications_active, 'Alertas configurables'),
                  _buildFeature(Icons.bubble_chart, 'Burbuja flotante'),
                  _buildFeature(Icons.battery_saver, 'Optimizado para batería'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Data source
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fuente de datos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Datos meteorológicos proporcionados por Open-Meteo, '
                    'un servicio de pronóstico del tiempo abierto y gratuito.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Privacy
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacidad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RainGuard procesa todos los datos localmente en tu dispositivo. '
                    'No se envían datos personales a servidores externos. '
                    'La ubicación se utiliza únicamente para consultar el clima.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Copyright
          Center(
            child: Text(
              '© 2024 RainGuard',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
