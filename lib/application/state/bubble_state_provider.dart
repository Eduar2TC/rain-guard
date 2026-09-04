import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rain_guard/platform/channels/method_channel_service.dart';
import 'package:rain_guard/domain/enums/rain_risk_state.dart';
import 'providers.dart';

// Bubble State
class BubbleState {
  final bool isVisible;
  final String currentState;
  final int? etaMinutes;
  final int x;
  final int y;

  const BubbleState({
    this.isVisible = false,
    this.currentState = 'idle',
    this.etaMinutes,
    this.x = 16,
    this.y = 64,
  });

  BubbleState copyWith({
    bool? isVisible,
    String? currentState,
    int? etaMinutes,
    int? x,
    int? y,
  }) {
    return BubbleState(
      isVisible: isVisible ?? this.isVisible,
      currentState: currentState ?? this.currentState,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  String get stateEmoji {
    switch (currentState) {
      case 'idle':
        return '☀️';
      case 'watch':
        return '🌦️';
      case 'approaching':
        return '🌧️';
      case 'warning':
        return '⚠️';
      case 'imminent':
        return '🚨';
      case 'raining':
        return '🌧️';
      default:
        return '?';
    }
  }

  String get etaDisplay {
    if (etaMinutes == null || etaMinutes! <= 0) return '';
    return '${etaMinutes}m';
  }
}

// Bubble State Notifier
class BubbleStateNotifier extends StateNotifier<BubbleState> {
  final MethodChannelService _methodChannel;

  BubbleStateNotifier(this._methodChannel) : super(const BubbleState()) {
    _init();
  }

  bool _pendingShow = false;

  void _init() {
    _methodChannel.onBubbleLongPress = _handleLongPress;
    _methodChannel.onBubblePositionChanged = _handlePositionChanged;
    _methodChannel.onOverlayPermissionResult = _handleOverlayPermissionResult;
  }

  void _handleOverlayPermissionResult(bool granted) async {
    if (!_pendingShow) return;
    _pendingShow = false;
    if (granted) {
      await _methodChannel.showBubble();
      state = state.copyWith(isVisible: true);
    }
  }

  void _handleLongPress() {
    // Long press handled by Android side (shows menu)
  }

  void _handlePositionChanged(Map<String, dynamic> data) {
    state = state.copyWith(
      x: data['x'] as int,
      y: data['y'] as int,
    );
  }

  Future<void> show() async {
    // Overlay permission is required to display the floating bubble on
    // Android 6+. Request it first so the bubble actually appears.
    if (!await _methodChannel.hasOverlayPermission()) {
      _pendingShow = true;
      await _methodChannel.requestOverlayPermission();
      return;
    }
    await _methodChannel.showBubble();
    state = state.copyWith(isVisible: true);
  }

  Future<void> hide() async {
    await _methodChannel.hideBubble();
    state = state.copyWith(isVisible: false);
  }

  Future<void> updateState(RainRiskState riskState, int? etaMinutes) async {
    final stateName = riskState.name;
    await _methodChannel.updateBubbleState(stateName, etaMinutes);
    state = state.copyWith(
      currentState: stateName,
      etaMinutes: etaMinutes,
    );
  }

  Future<void> setPosition(int x, int y) async {
    await _methodChannel.setBubblePosition(x.toDouble(), y.toDouble());
    state = state.copyWith(x: x, y: y);
  }

  @override
  void dispose() {
    _methodChannel.onBubbleLongPress = null;
    _methodChannel.onBubblePositionChanged = null;
    _methodChannel.onOverlayPermissionResult = null;
    super.dispose();
  }
}

// Provider
final bubbleStateProvider = StateNotifierProvider<BubbleStateNotifier, BubbleState>((ref) {
  final methodChannel = ref.watch(methodChannelServiceProvider);
  return BubbleStateNotifier(methodChannel);
});
