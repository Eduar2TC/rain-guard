import 'package:flutter/material.dart';

class MonitoringToggle extends StatelessWidget {
  final bool isActive;
  final bool isPaused;
  final VoidCallback onToggle;
  final VoidCallback? onPause;

  const MonitoringToggle({
    super.key,
    required this.isActive,
    this.isPaused = false,
    required this.onToggle,
    this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Main toggle button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onToggle,
            icon: Icon(
              isActive ? Icons.stop : Icons.play_arrow,
            ),
            label: Text(
              isActive ? 'DETENER MONITOREO' : 'INICIAR MONITOREO',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Pause button (only when active)
        if (isActive && onPause != null) ...[
          const SizedBox(width: 12),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: onPause,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPaused ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                size: 28,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
