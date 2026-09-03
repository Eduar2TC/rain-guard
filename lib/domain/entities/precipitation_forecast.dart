class PrecipitationInterval {
  final DateTime time;
  final double precipitation;
  final double rain;
  final double showers;

  const PrecipitationInterval({
    required this.time,
    required this.precipitation,
    required this.rain,
    required this.showers,
  });

  bool get hasPrecipitation => precipitation > 0.1;

  Map<String, dynamic> toMap() => {
        'time': time.toIso8601String(),
        'precipitation': precipitation,
        'rain': rain,
        'showers': showers,
      };

  factory PrecipitationInterval.fromMap(Map<String, dynamic> map) =>
      PrecipitationInterval(
        time: DateTime.parse(map['time']),
        precipitation: (map['precipitation'] as num).toDouble(),
        rain: (map['rain'] as num).toDouble(),
        showers: (map['showers'] as num).toDouble(),
      );
}

class PrecipitationForecast {
  final DateTime timestamp;
  final List<PrecipitationInterval> intervals;

  const PrecipitationForecast({
    required this.timestamp,
    required this.intervals,
  });

  Duration? get firstPrecipitationEta {
    final now = DateTime.now();
    for (final interval in intervals) {
      if (interval.hasPrecipitation && interval.time.isAfter(now)) {
        return interval.time.difference(now);
      }
    }
    return null;
  }

  double get maxPrecipitationInNext15Min {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(minutes: 15));
    return intervals
        .where((i) => i.time.isAfter(now) && i.time.isBefore(cutoff))
        .map((i) => i.precipitation)
        .fold(0.0, (a, b) => a > b ? a : b);
  }

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'intervals': intervals.map((i) => i.toMap()).toList(),
      };

  factory PrecipitationForecast.fromMap(Map<String, dynamic> map) =>
      PrecipitationForecast(
        timestamp: DateTime.parse(map['timestamp']),
        intervals: (map['intervals'] as List)
            .map((i) => PrecipitationInterval.fromMap(i))
            .toList(),
      );
}
