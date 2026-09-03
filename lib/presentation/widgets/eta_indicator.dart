import 'package:flutter/material.dart';

import '../../application/state/prediction_state_provider.dart';
import '../../core/constants/theme.dart';
import '../../domain/enums/rain_risk_state.dart';

class EtaIndicator extends StatelessWidget {
  final PredictionState predictionState;

  const EtaIndicator({super.key, required this.predictionState});

  @override
  Widget build(BuildContext context) {
    if (predictionState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (predictionState.error != null) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error: ${predictionState.error}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final prediction = predictionState.prediction;
    if (prediction == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Sin predicción disponible'),
        ),
      );
    }

    final color = AppColors.getColorForState(prediction.state.name);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // State emoji and text
            Text(
              prediction.state.emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),

            // ETA
            if (prediction.hasValidEta)
              Text(
                prediction.etaDisplay,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              )
            else
              Text(
                prediction.state.displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),

            const SizedBox(height: 8),

            // State description
            Text(
              _getStateDescription(prediction.state),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Confidence and source
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChip(
                  icon: Icons.insights,
                  label: prediction.confidenceDisplay,
                  color: _getConfidenceColor(prediction.confidence),
                ),
                const SizedBox(width: 8),
                _buildChip(
                  icon: Icons.source,
                  label: prediction.sourceDisplay,
                  color: Colors.grey,
                ),
              ],
            ),

            // Direction if available
            if (prediction.directionDisplay.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.navigation, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Dirección: ${prediction.directionDisplay}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(dynamic confidence) {
    switch (confidence) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStateDescription(RainRiskState state) {
    switch (state) {
      case RainRiskState.idle:
        return 'No se detecta lluvia cercana';
      case RainRiskState.watch:
        return 'Posible lluvia más tarde';
      case RainRiskState.approaching:
        return 'La lluvia parece acercarse';
      case RainRiskState.warning:
        return 'Busca refugio';
      case RainRiskState.imminent:
        return 'Refúgiate ahora';
      case RainRiskState.raining:
        return 'Está lloviendo en tu ubicación';
      case RainRiskState.passed:
        return 'La lluvia se alejó';
      case RainRiskState.unknown:
        return 'Esperando datos...';
    }
  }
}
