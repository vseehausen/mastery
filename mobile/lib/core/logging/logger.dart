import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Log levels for structured logging
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Structured logger for the Mastery app
class Logger {
  Logger(this.name);

  final String name;
  static bool _enabled = kDebugMode;

  /// Enable or disable logging globally
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Log a debug message
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  /// Log an info message
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// Log a warning message
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Log an error message
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  void _log(LogLevel level, String message, Object? error, StackTrace? stackTrace) {
    if (!_enabled) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final logMessage = '[$timestamp] $levelStr [$name] $message';

    // Use developer.log for structured logging
    developer.log(
      logMessage,
      name: name,
      level: _levelToInt(level),
      error: error,
      stackTrace: stackTrace,
    );

    // Also print to console in debug mode
    if (kDebugMode) {
      // ignore: avoid_print
      print(logMessage);
      if (error != null) {
        // ignore: avoid_print
        print('  Error: $error');
      }
      if (stackTrace != null) {
        // ignore: avoid_print
        print('  Stack: $stackTrace');
      }
    }
  }

  int _levelToInt(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}

/// Global logger factory
class Loggers {
  static final Map<String, Logger> _loggers = {};

  /// Get a logger for the given name
  static Logger get(String name) {
    return _loggers.putIfAbsent(name, () => Logger(name));
  }

  /// Predefined loggers
  static Logger get import => get('Import');
  static Logger get sync => get('Sync');
  static Logger get database => get('Database');
  static Logger get auth => get('Auth');
  static Logger get ui => get('UI');
}
