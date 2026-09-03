import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/state/bubble_state_provider.dart';

class BubblePreview extends ConsumerWidget {
  const BubblePreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bubbleState = ref.watch(bubbleStateProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Preview of bubble
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStateColor(bubbleState.currentState),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  bubbleState.stateEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Burbuja flotante',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (bubbleState.etaDisplay.isNotEmpty)
                    Text(
                      'ETA: ${bubbleState.etaDisplay}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),

            // Toggle
            Switch(
              value: bubbleState.isVisible,
              onChanged: (_) {
                ref.read(bubbleStateProvider.notifier).toggle();
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'idle':
        return Colors.green;
      case 'watch':
        return Colors.amber;
      case 'approaching':
        return Colors.orange;
      case 'warning':
        return Colors.deepOrange;
      case 'imminent':
        return Colors.red;
      case 'raining':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
