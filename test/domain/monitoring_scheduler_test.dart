import 'package:flutter_test/flutter_test.dart';
import 'package:rain_guard/domain/enums/rain_risk_state.dart';
import 'package:rain_guard/domain/services/monitoring_scheduler.dart';

void main() {
  group('MonitoringScheduler', () {
    test('starts with normal interval', () {
      final scheduler = MonitoringScheduler(onUpdate: () {});

      expect(scheduler.currentInterval.inSeconds, 300); // 5 min

      scheduler.dispose();
    });

    test('adjusts interval based on risk state', () {
      final scheduler = MonitoringScheduler(onUpdate: () {});

      // Normal state
      scheduler.update(riskState: RainRiskState.idle);
      expect(scheduler.currentInterval.inSeconds, 300);

      // Warning state
      scheduler.update(riskState: RainRiskState.warning);
      expect(scheduler.currentInterval.inSeconds, 90);

      // Approaching state
      scheduler.update(riskState: RainRiskState.approaching);
      expect(scheduler.currentInterval.inSeconds, 180);

      // Watch state
      scheduler.update(riskState: RainRiskState.watch);
      expect(scheduler.currentInterval.inSeconds, 300);

      // Raining state
      scheduler.update(riskState: RainRiskState.raining);
      expect(scheduler.currentInterval.inSeconds, 180);

      scheduler.dispose();
    });

    test('adjusts interval based on battery level', () {
      final scheduler = MonitoringScheduler(onUpdate: () {});

      // Normal battery
      scheduler.update(riskState: RainRiskState.idle, batteryLevel: 50);
      expect(scheduler.currentInterval.inSeconds, 300);

      // Low battery (5-15%)
      scheduler.update(riskState: RainRiskState.idle, batteryLevel: 10);
      expect(scheduler.currentInterval.inSeconds, 600); // Double

      // Critical battery (<5%)
      scheduler.update(riskState: RainRiskState.idle, batteryLevel: 3);
      expect(scheduler.currentInterval.inSeconds, 900); // Triple

      scheduler.dispose();
    });

    test('adjusts interval based on network availability', () {
      final scheduler = MonitoringScheduler(onUpdate: () {});

      // Network available
      scheduler.update(riskState: RainRiskState.idle, networkAvailable: true);
      expect(scheduler.currentInterval.inSeconds, 300);

      // No network
      scheduler.update(riskState: RainRiskState.idle, networkAvailable: false);
      expect(scheduler.currentInterval.inSeconds, 600); // Double

      scheduler.dispose();
    });

    test('combines battery and network adjustments', () {
      final scheduler = MonitoringScheduler(onUpdate: () {});

      // Low battery + no network
      scheduler.update(
        riskState: RainRiskState.idle,
        batteryLevel: 10,
        networkAvailable: false,
      );

      // Should be tripled (low battery) * doubled (no network) = 6x
      // But we use addition, so it's 300 * 2 (battery) * 2 (network) = 1200
      expect(scheduler.currentInterval.inSeconds, 1200);

      scheduler.dispose();
    });

    test('reset clears state', () {
      final scheduler = MonitoringScheduler(onUpdate: () {});

      scheduler.update(riskState: RainRiskState.warning, batteryLevel: 10);
      scheduler.reset();

      expect(scheduler.currentInterval.inSeconds, 300);

      scheduler.dispose();
    });
  });
}
