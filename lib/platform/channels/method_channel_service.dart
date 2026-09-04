import 'package:flutter/services.dart';

class MethodChannelService {
  static const _channel = MethodChannel('rainguard/monitoring');

  final Function(Map<String, dynamic>)? onSettingsChanged;
  final Function(Map<String, dynamic>)? onLocationUpdate;
  final Function(Map<String, dynamic>)? onAlert;

  Function()? onBubbleLongPress;
  Function(Map<String, dynamic>)? onBubblePositionChanged;
  Function(Map<String, dynamic>)? onBatteryChanged;
  Future<bool> Function()? onRequestOverlayPermission;
  Function(bool)? onOverlayPermissionResult;

  MethodChannelService({this.onSettingsChanged, this.onLocationUpdate, this.onAlert}) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSettingsChanged':
        if (onSettingsChanged != null) {
          onSettingsChanged!(Map<String, dynamic>.from(call.arguments));
        }
        break;
      case 'onLocationUpdate':
        if (onLocationUpdate != null) {
          onLocationUpdate!(Map<String, dynamic>.from(call.arguments));
        }
        break;
      case 'onAlert':
        if (onAlert != null) {
          onAlert!(Map<String, dynamic>.from(call.arguments));
        }
        break;
      case 'onBubbleLongPress':
        onBubbleLongPress?.call();
        break;
      case 'onBubblePositionChanged':
        if (onBubblePositionChanged != null) {
          onBubblePositionChanged!(Map<String, dynamic>.from(call.arguments));
        }
        break;
      case 'onBatteryChanged':
        if (onBatteryChanged != null) {
          onBatteryChanged!(Map<String, dynamic>.from(call.arguments));
        }
        break;
      case 'onOverlayPermissionResult':
        if (onOverlayPermissionResult != null) {
          onOverlayPermissionResult!(call.arguments == true);
        }
        break;
      case 'onLocationPermissionResult':
        // Handle location permission result
        break;
      case 'onBackgroundLocationPermissionResult':
        // Handle background location permission result
        break;
      case 'onNotificationPermissionResult':
        // Handle notification permission result
        break;
      default:
        throw MissingPluginException('Not implemented: ${call.method}');
    }
  }

  // Monitoring
  Future<void> startMonitoring() async {
    await _channel.invokeMethod('startMonitoring');
  }

  Future<void> stopMonitoring() async {
    await _channel.invokeMethod('stopMonitoring');
  }

  Future<void> pauseMonitoring() async {
    await _channel.invokeMethod('pauseMonitoring');
  }

  Future<void> resumeMonitoring() async {
    await _channel.invokeMethod('resumeMonitoring');
  }

  // Bubble
  Future<void> showBubble() async {
    await _channel.invokeMethod('showBubble');
  }

  Future<void> hideBubble() async {
    await _channel.invokeMethod('hideBubble');
  }

  Future<void> setBubblePosition(double x, double y) async {
    await _channel.invokeMethod('setBubblePosition', {'x': x, 'y': y});
  }

  Future<Map<String, dynamic>?> getBubblePosition() async {
    final result = await _channel.invokeMethod('getBubblePosition');
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  Future<void> updateBubbleState(String state, int? etaMinutes) async {
    await _channel.invokeMethod('updateBubbleState', {
      'state': state,
      'etaMinutes': etaMinutes,
    });
  }

  // Settings
  Future<void> setSettings(Map<String, dynamic> settings) async {
    await _channel.invokeMethod('setSettings', settings);
  }

  // Location
  Future<void> startLocationUpdates() async {
    await _channel.invokeMethod('startLocationUpdates');
  }

  Future<void> stopLocationUpdates() async {
    await _channel.invokeMethod('stopLocationUpdates');
  }

  Future<Map<String, dynamic>?> getLastKnownLocation() async {
    final result = await _channel.invokeMethod('getLastKnownLocation');
    if (result == null) return null;
    return Map<String, dynamic>.from(result);
  }

  Future<bool> hasLocationPermission() async {
    final result = await _channel.invokeMethod('hasLocationPermission');
    return result == true;
  }

  Future<bool> requestLocationPermission() async {
    final result = await _channel.invokeMethod('requestLocationPermission');
    return result == true;
  }

  Future<bool> requestBackgroundLocationPermission() async {
    final result = await _channel.invokeMethod('requestBackgroundLocationPermission');
    return result == true;
  }

  // Permissions
  Future<bool> requestOverlayPermission() async {
    final result = await _channel.invokeMethod('requestOverlayPermission');
    return result == true;
  }

  Future<bool> hasOverlayPermission() async {
    final result = await _channel.invokeMethod('hasOverlayPermission');
    return result == true;
  }

  Future<bool> requestNotificationPermission() async {
    final result = await _channel.invokeMethod('requestNotificationPermission');
    return result == true;
  }

  // State
  Future<bool> isMonitoring() async {
    final result = await _channel.invokeMethod('isMonitoring');
    return result == true;
  }

  Future<bool> isBubbleVisible() async {
    final result = await _channel.invokeMethod('isBubbleVisible');
    return result == true;
  }

  // Battery
  Future<void> checkBattery() async {
    await _channel.invokeMethod('checkBattery');
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
  }

  // Alerts
  Future<void> playAlertSound() async {
    await _channel.invokeMethod('playAlertSound');
  }

  Future<void> vibrate() async {
    await _channel.invokeMethod('vibrate');
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required int priority,
  }) async {
    await _channel.invokeMethod('showNotification', {
      'title': title,
      'body': body,
      'priority': priority,
    });
  }

  Future<void> updateNotification({
    required String body,
  }) async {
    await _channel.invokeMethod('updateNotification', {
      'body': body,
    });
  }

  Future<void> cancelNotification() async {
    await _channel.invokeMethod('cancelNotification');
  }
}
