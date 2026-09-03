import '../enums/alert_priority.dart';
import '../enums/rain_risk_state.dart';

class AlertDecision {
  final bool shouldNotify;
  final RainRiskState newState;
  final String message;
  final AlertPriority priority;
  final bool playSound;
  final bool vibrate;

  const AlertDecision({
    required this.shouldNotify,
    required this.newState,
    required this.message,
    required this.priority,
    this.playSound = false,
    this.vibrate = false,
  });

  AlertDecision.noAlert()
      : shouldNotify = false,
        newState = RainRiskState.idle,
        message = '',
        priority = AlertPriority.low,
        playSound = false,
        vibrate = false;

  Map<String, dynamic> toMap() => {
        'shouldNotify': shouldNotify,
        'newState': newState.name,
        'message': message,
        'priority': priority.name,
        'playSound': playSound,
        'vibrate': vibrate,
      };
}
