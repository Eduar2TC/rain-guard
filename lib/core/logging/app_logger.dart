enum LogLevel {
  debug,
  info,
  warning,
  error;

  String get name {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final dynamic error;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
  });

  @override
  String toString() {
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
    return '[$timeStr] [${level.name}] [$tag] $message';
  }
}

class AppLogger {
  static final AppLogger _instance = AppLogger._();
  factory AppLogger() => _instance;
  AppLogger._();

  final List<LogEntry> _logs = [];
  final int _maxLogs = 1000;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void debug(String tag, String message) {
    _log(LogLevel.debug, tag, message);
  }

  void info(String tag, String message) {
    _log(LogLevel.info, tag, message);
  }

  void warning(String tag, String message, [dynamic error]) {
    _log(LogLevel.warning, tag, message, error);
  }

  void error(String tag, String message, [dynamic error]) {
    _log(LogLevel.error, tag, message, error);
  }

  void _log(LogLevel level, String tag, String message, [dynamic error]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
    );

    _logs.add(entry);

    // Keep only the last N logs
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Print to console in debug mode
    assert(() {
      // ignore: avoid_print - Debug-only console logging, stripped in release builds.
      print(entry.toString());
      return true;
    }());
  }

  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level == level).toList();
  }

  List<LogEntry> getLogsByTag(String tag) {
    return _logs.where((log) => log.tag == tag).toList();
  }

  List<LogEntry> getRecentLogs({int count = 100}) {
    final start = _logs.length - count;
    if (start < 0) return List.from(_logs);
    return _logs.sublist(start);
  }

  void clear() {
    _logs.clear();
  }
}

// Global logger instance
final logger = AppLogger();

// Tag constants
class LogTags {
  static const String location = 'LOCATION';
  static const String weather = 'WEATHER';
  static const String prediction = 'PREDICTION';
  static const String alert = 'ALERT';
  static const String monitoring = 'MONITORING';
  static const String bubble = 'BUBBLE';
  static const String battery = 'BATTERY';
  static const String notification = 'NOTIFICATION';
  static const String permission = 'PERMISSION';
  static const String network = 'NETWORK';
}
