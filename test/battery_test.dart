import 'package:flutter_test/flutter_test.dart';
import 'package:rain_guard/application/state/battery_state_provider.dart';

void main() {
  group('BatteryState', () {
    test('creates with default values', () {
      const state = BatteryState();

      expect(state.level, 100);
      expect(state.percentage, 100);
      expect(state.isCharging, false);
      expect(state.isLowBattery, false);
      expect(state.isCriticalBattery, false);
    });

    test('isLowBattery returns true when percentage < 15 and not charging', () {
      const lowBattery = BatteryState(percentage: 10, isCharging: false);
      expect(lowBattery.isLowBattery, true);

      const lowButCharging = BatteryState(percentage: 10, isCharging: true);
      expect(lowButCharging.isLowBattery, false);

      const normalBattery = BatteryState(percentage: 50, isCharging: false);
      expect(normalBattery.isLowBattery, false);
    });

    test('isCriticalBattery returns true when percentage < 5 and not charging', () {
      const criticalBattery = BatteryState(percentage: 3, isCharging: false);
      expect(criticalBattery.isCriticalBattery, true);

      const criticalButCharging = BatteryState(percentage: 3, isCharging: true);
      expect(criticalButCharging.isCriticalBattery, false);
    });

    test('statusText returns correct string', () {
      const charging = BatteryState(isCharging: true, chargingSource: 'USB');
      expect(charging.statusText, 'Cargando (USB)');

      const critical = BatteryState(percentage: 3, isCharging: false);
      expect(critical.statusText, 'Batería crítica');

      const low = BatteryState(percentage: 10, isCharging: false);
      expect(low.statusText, 'Batería baja');

      const normal = BatteryState(percentage: 50, isCharging: false);
      expect(normal.statusText, '50%');
    });

    test('copyWith works correctly', () {
      const original = BatteryState();
      final modified = original.copyWith(
        percentage: 75,
        isCharging: true,
      );

      expect(modified.percentage, 75);
      expect(modified.isCharging, true);
      expect(modified.level, 100); // Unchanged
    });
  });
}
