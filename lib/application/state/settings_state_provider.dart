import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/enums/monitoring_mode.dart';
import '../../platform/channels/method_channel_service.dart';
import 'providers.dart';
import 'bubble_state_provider.dart';
import 'alert_state_provider.dart';

// Settings State
class SettingsState {
  final bool bubbleEnabled;
  final MonitoringMode monitoringMode;
  final bool alertsEnabled;
  final double pollingInterval;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool isLoaded;

  const SettingsState({
    this.bubbleEnabled = true,
    this.monitoringMode = MonitoringMode.full,
    this.alertsEnabled = true,
    this.pollingInterval = 5.0,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.isLoaded = false,
  });

  SettingsState copyWith({
    bool? bubbleEnabled,
    MonitoringMode? monitoringMode,
    bool? alertsEnabled,
    double? pollingInterval,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? isLoaded,
  }) {
    return SettingsState(
      bubbleEnabled: bubbleEnabled ?? this.bubbleEnabled,
      monitoringMode: monitoringMode ?? this.monitoringMode,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      pollingInterval: pollingInterval ?? this.pollingInterval,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

// Settings State Notifier
class SettingsStateNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;
  final Ref _ref;

  SettingsStateNotifier(this._prefs, this._ref) : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    state = SettingsState(
      bubbleEnabled: _prefs.getBool('bubble_enabled') ?? true,
      monitoringMode: MonitoringMode.values[_prefs.getInt('monitoring_mode') ?? 3],
      alertsEnabled: _prefs.getBool('alerts_enabled') ?? true,
      pollingInterval: _prefs.getDouble('polling_interval') ?? 5.0,
      soundEnabled: _prefs.getBool('sound_enabled') ?? true,
      vibrationEnabled: _prefs.getBool('vibration_enabled') ?? true,
      isLoaded: true,
    );

    // Apply loaded settings to providers
    _applyBubbleSettings();
    _applyAlertSettings();
  }

  Future<void> setBubbleEnabled(bool enabled) async {
    await _prefs.setBool('bubble_enabled', enabled);
    state = state.copyWith(bubbleEnabled: enabled);
    _applyBubbleSettings();
  }

  Future<void> setMonitoringMode(MonitoringMode mode) async {
    await _prefs.setInt('monitoring_mode', mode.index);
    state = state.copyWith(monitoringMode: mode);
  }

  Future<void> setAlertsEnabled(bool enabled) async {
    await _prefs.setBool('alerts_enabled', enabled);
    state = state.copyWith(alertsEnabled: enabled);
    _applyAlertSettings();
  }

  Future<void> setPollingInterval(double minutes) async {
    await _prefs.setDouble('polling_interval', minutes);
    state = state.copyWith(pollingInterval: minutes);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool('sound_enabled', enabled);
    state = state.copyWith(soundEnabled: enabled);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    await _prefs.setBool('vibration_enabled', enabled);
    state = state.copyWith(vibrationEnabled: enabled);
  }

  void _applyBubbleSettings() {
    final bubbleNotifier = _ref.read(bubbleStateProvider.notifier);
    if (state.bubbleEnabled) {
      bubbleNotifier.show();
    } else {
      bubbleNotifier.hide();
    }
  }

  void _applyAlertSettings() {
    final alertNotifier = _ref.read(alertStateProvider.notifier);
    if (!state.alertsEnabled) {
      // If alerts are disabled, we should stop notifications
      // but keep monitoring active
    }
  }

  Duration get pollingIntervalDuration => Duration(
        milliseconds: (state.pollingInterval * 60 * 1000).toInt(),
      );
}

// Provider
final settingsStateProvider = StateNotifierProvider<SettingsStateNotifier, SettingsState>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return SettingsStateNotifier(prefs, ref);
});
