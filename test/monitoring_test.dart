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
      int updateCount = 0;
      final scheduler = MonitoringScheduler(onUpdate: () => updateCount++);

      // Normal state
      scheduler.update(riskState: RainRiskState.idle);
      expect(scheduler.currentInterval.inSeconds, 300);

      // Warning state
      scheduler.update(riskState: RainRiskState.warning);
      expect(scheduler.currentInterval.inSeconds, 90);

      // Approaching state
      scheduler.update(riskState: RainRiskState.approaching);
      expect(scheduler.currentInterval.inSeconds, 180);

      scheduler.dispose();
    });

    test('adjusts interval based on battery level', () {
      final scheduler = MonitoringScheduler(onUpdate: () {});

      // Normal battery
      scheduler.update(riskState: RainRiskState.idle, batteryLevel: 50);
      expect(scheduler.currentInterval.inSeconds, 300);

      // Low battery
      scheduler.update(riskState: RainRiskState.idle, batteryLevel: 10);
      expect(scheduler.currentInterval.inSeconds, 600); // Double

      // Critical battery
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
  });
}
