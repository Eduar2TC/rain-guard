import 'package:flutter_test/flutter_test.dart';
import 'package:rain_guard/application/state/bubble_state_provider.dart';

void main() {
  group('BubbleState', () {
    test('creates with default values', () {
      const state = BubbleState();

      expect(state.isVisible, false);
      expect(state.currentState, 'idle');
      expect(state.etaMinutes, null);
    });

    test('copyWith works correctly', () {
      const state = BubbleState();
      final newState = state.copyWith(
        isVisible: true,
        currentState: 'warning',
        etaMinutes: 5,
      );

      expect(newState.isVisible, true);
      expect(newState.currentState, 'warning');
      expect(newState.etaMinutes, 5);
    });

    test('stateEmoji returns correct emoji', () {
      const idleState = BubbleState(currentState: 'idle');
      expect(idleState.stateEmoji, '☀️');

      const watchState = BubbleState(currentState: 'watch');
      expect(watchState.stateEmoji, '🌦️');

      const warningState = BubbleState(currentState: 'warning');
      expect(warningState.stateEmoji, '⚠️');

      const imminentState = BubbleState(currentState: 'imminent');
      expect(imminentState.stateEmoji, '🚨');

      const rainingState = BubbleState(currentState: 'raining');
      expect(rainingState.stateEmoji, '🌧️');
    });

    test('etaDisplay returns formatted string', () {
      const noEta = BubbleState(etaMinutes: null);
      expect(noEta.etaDisplay, '');

      const zeroEta = BubbleState(etaMinutes: 0);
      expect(zeroEta.etaDisplay, '');

      const fiveEta = BubbleState(etaMinutes: 5);
      expect(fiveEta.etaDisplay, '5m');

      const fifteenEta = BubbleState(etaMinutes: 15);
      expect(fifteenEta.etaDisplay, '15m');
    });
  });
}
