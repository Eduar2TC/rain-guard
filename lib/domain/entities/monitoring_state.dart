import '../enums/monitoring_mode.dart';
import '../enums/prediction_confidence.dart';
import '../enums/rain_intensity.dart';
import '../enums/rain_risk_state.dart';

class MonitoringState {
  final bool isMonitoring;
  final RainRiskState riskState;
  final Duration? eta;
  final PredictionConfidence confidence;
  final RainIntensity rainIntensity;
  final double? latitude;
  final double? longitude;
  final double speed;
  final double bearing;
  final DateTime? lastUpdate;
  final Duration? dataAge;
  final bool networkAvailable;
  final double batteryLevel;
  final bool bubbleVisible;
  final MonitoringMode monitoringMode;
  final bool isPaused;

  const MonitoringState({
    this.isMonitoring = false,
    this.riskState = RainRiskState.unknown,
    this.eta,
    this.confidence = PredictionConfidence.none,
    this.rainIntensity = RainIntensity.none,
    this.latitude,
    this.longitude,
    this.speed = 0,
    this.bearing = 0,
    this.lastUpdate,
    this.dataAge,
    this.networkAvailable = false,
    this.batteryLevel = 100,
    this.bubbleVisible = false,
    this.monitoringMode = MonitoringMode.full,
    this.isPaused = false,
  });

  int? get etaMinutes => eta?.inMinutes;

  bool get hasLocation => latitude != null && longitude != null;

  bool get isDataStale {
    if (dataAge == null) return true;
    return dataAge!.inSeconds > 600; // 10 minutes
  }

  MonitoringState copyWith({
    bool? isMonitoring,
    RainRiskState? riskState,
    Duration? eta,
    PredictionConfidence? confidence,
    RainIntensity? rainIntensity,
    double? latitude,
    double? longitude,
    double? speed,
    double? bearing,
    DateTime? lastUpdate,
    Duration? dataAge,
    bool? networkAvailable,
    double? batteryLevel,
    bool? bubbleVisible,
    MonitoringMode? monitoringMode,
    bool? isPaused,
  }) {
    return MonitoringState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      riskState: riskState ?? this.riskState,
      eta: eta ?? this.eta,
      confidence: confidence ?? this.confidence,
      rainIntensity: rainIntensity ?? this.rainIntensity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      dataAge: dataAge ?? this.dataAge,
      networkAvailable: networkAvailable ?? this.networkAvailable,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      bubbleVisible: bubbleVisible ?? this.bubbleVisible,
      monitoringMode: monitoringMode ?? this.monitoringMode,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  Map<String, dynamic> toMap() => {
        'isMonitoring': isMonitoring,
        'riskState': riskState.name,
        'etaMinutes': etaMinutes,
        'confidence': confidence.name,
        'rainIntensity': rainIntensity.name,
        'latitude': latitude,
        'longitude': longitude,
        'speed': speed,
        'bearing': bearing,
        'lastUpdate': lastUpdate?.toIso8601String(),
        'dataAgeSeconds': dataAge?.inSeconds,
        'networkAvailable': networkAvailable,
        'batteryLevel': batteryLevel,
        'bubbleVisible': bubbleVisible,
        'monitoringMode': monitoringMode.name,
        'isPaused': isPaused,
      };

  factory MonitoringState.fromMap(Map<String, dynamic> map) =>
      MonitoringState(
        isMonitoring: map['isMonitoring'] as bool? ?? false,
        riskState: RainRiskState.fromString(map['riskState'] ?? 'unknown'),
        eta: map['etaMinutes'] != null
            ? Duration(minutes: map['etaMinutes'] as int)
            : null,
        confidence: PredictionConfidence.values.firstWhere(
          (e) => e.name == map['confidence'],
          orElse: () => PredictionConfidence.none,
        ),
        rainIntensity: RainIntensity.values.firstWhere(
          (e) => e.name == map['rainIntensity'],
          orElse: () => RainIntensity.none,
        ),
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        speed: (map['speed'] as num?)?.toDouble() ?? 0,
        bearing: (map['bearing'] as num?)?.toDouble() ?? 0,
        lastUpdate: map['lastUpdate'] != null
            ? DateTime.parse(map['lastUpdate'])
            : null,
        dataAge: map['dataAgeSeconds'] != null
            ? Duration(seconds: map['dataAgeSeconds'] as int)
            : null,
        networkAvailable: map['networkAvailable'] as bool? ?? false,
        batteryLevel: (map['batteryLevel'] as num?)?.toDouble() ?? 100,
        bubbleVisible: map['bubbleVisible'] as bool? ?? false,
        monitoringMode: MonitoringMode.values.firstWhere(
          (e) => e.name == map['monitoringMode'],
          orElse: () => MonitoringMode.full,
        ),
        isPaused: map['isPaused'] as bool? ?? false,
      );
}
