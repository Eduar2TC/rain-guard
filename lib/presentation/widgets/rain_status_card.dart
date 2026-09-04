import 'package:flutter/material.dart';

import 'package:rain_guard/core/constants/theme.dart';
import 'package:rain_guard/domain/entities/monitoring_state.dart';

class RainStatusCard extends StatelessWidget {
  final MonitoringState state;

  const RainStatusCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Weather emoji
            Text(
              state.riskState.emoji,
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),

            // Status text
            Text(
              state.riskState.displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.getColorForState(state.riskState.name),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // ETA or additional info
            if (state.eta != null)
              Text(
                '~${state.eta!.inMinutes} min',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.getColorForState(state.riskState.name),
                    ),
              ),

            if (state.isDataStale)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Datos desactualizados',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                ),
              ),

            if (!state.networkAvailable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Sin conexión',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
