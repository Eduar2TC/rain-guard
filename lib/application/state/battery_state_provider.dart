import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rain_guard/platform/channels/method_channel_service.dart';
import 'providers.dart';

// Battery State
class BatteryState {
  final int level;
  final double percentage;
  final bool isCharging;
  final String chargingSource;
  final bool isPowerSaveMode;
  final bool isIgnoringBatteryOptimizations;

  const BatteryState({
    this.level = 100,
    this.percentage = 100,
    this.isCharging = false,
    this.chargingSource = 'None',
    this.isPowerSaveMode = false,
    this.isIgnoringBatteryOptimizations = true,
  });

  bool get isLowBattery => percentage < 15 && !isCharging;
  bool get isCriticalBattery => percentage < 5 && !isCharging;

  String get statusText {
    if (isCharging) {
      return 'Cargando ($chargingSource)';
    }
    if (isCriticalBattery) {
      return 'Batería crítica';
    }
    if (isLowBattery) {
      return 'Batería baja';
    }
    return '${percentage.toStringAsFixed(0)}%';
  }

  BatteryState copyWith({
    int? level,
    double? percentage,
    bool? isCharging,
    String? chargingSource,
    bool? isPowerSaveMode,
    bool? isIgnoringBatteryOptimizations,
  }) {
    return BatteryState(
      level: level ?? this.level,
      percentage: percentage ?? this.percentage,
      isCharging: isCharging ?? this.isCharging,
      chargingSource: chargingSource ?? this.chargingSource,
      isPowerSaveMode: isPowerSaveMode ?? this.isPowerSaveMode,
      isIgnoringBatteryOptimizations: isIgnoringBatteryOptimizations ?? this.isIgnoringBatteryOptimizations,
    );
  }
}

// Battery State Notifier
class BatteryStateNotifier extends StateNotifier<BatteryState> {
  final MethodChannelService _methodChannel;
  Timer? _checkTimer;

  BatteryStateNotifier(this._methodChannel) : super(const BatteryState()) {
    _init();
  }

  void _init() {
    _methodChannel.onBatteryChanged = _onBatteryChanged;
    _checkBattery();
    // Check periodically
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkBattery());
  }

  void _onBatteryChanged(Map<String, dynamic> data) {
    state = BatteryState(
      level: data['level'] as int? ?? 100,
      percentage: (data['percentage'] as num?)?.toDouble() ?? 100,
      isCharging: data['isCharging'] as bool? ?? false,
      chargingSource: data['chargingSource'] as String? ?? 'None',
      isPowerSaveMode: data['isPowerSaveMode'] as bool? ?? false,
      isIgnoringBatteryOptimizations: data['isIgnoringBatteryOptimizations'] as bool? ?? true,
    );
  }

  Future<void> _checkBattery() async {
    await _methodChannel.checkBattery();
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    await _methodChannel.requestIgnoreBatteryOptimizations();
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _methodChannel.onBatteryChanged = null;
    super.dispose();
  }
}

// Provider
final batteryStateProvider = StateNotifierProvider<BatteryStateNotifier, BatteryState>((ref) {
  final methodChannel = ref.watch(methodChannelServiceProvider);
  return BatteryStateNotifier(methodChannel);
});
