import 'dart:async';
import 'dart:developer' as developer;

import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight structured decision logger that batch-inserts to Supabase.
///
/// Usage:
///   DecisionLog.init(supabaseClient);
///   DecisionLog.log('event_type', {'key': 'value'});
///   DecisionLog.flush();   // called automatically on timer / app pause
///   DecisionLog.dispose(); // on app shutdown
class DecisionLog {
  DecisionLog._();

  static SupabaseClient? _client;
  static String? _appVersion;
  static final List<Map<String, dynamic>> _buffer = [];
  static Timer? _flushTimer;
  static bool _flushing = false;

  static const int _maxBuffer = 50;
  static const int _flushThreshold = 10;
  static const Duration _flushInterval = Duration(seconds: 30);

  /// Initialize with a Supabase client. Call once after Supabase init.
  static Future<void> init(SupabaseClient client) async {
    _client = client;
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _appVersion = 'unknown';
    }
    _startTimer();
  }

  /// Log a decision event. Appended to in-memory buffer.
  static void log(String eventType, [Map<String, dynamic> data = const {}]) {
    if (_client == null) return;

    _buffer.add({
      'event_type': eventType,
      'data': data,
      'app_version': _appVersion,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    // Cap buffer size
    if (_buffer.length > _maxBuffer) {
      _buffer.removeRange(0, _buffer.length - _maxBuffer);
    }

    if (_buffer.length >= _flushThreshold) {
      flush();
    }
  }

  /// Batch-insert buffered events to Supabase.
  static Future<void> flush() async {
    if (_flushing || _buffer.isEmpty || _client == null) return;
    _flushing = true;

    final userId = _client!.auth.currentUser?.id;
    if (userId == null) {
      _flushing = false;
      return;
    }

    final batch = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();

    try {
      final rows = batch
          .map((e) => {
                'user_id': userId,
                'event_type': e['event_type'],
                'data': e['data'],
                'app_version': e['app_version'],
                'created_at': e['created_at'],
              })
          .toList();
      await _client!.from('decision_log').insert(rows);
    } catch (e) {
      developer.log(
        'DecisionLog flush failed: $e',
        name: 'DecisionLog',
        level: 900,
      );
      // Discard batch on failure — don't re-add to avoid infinite loop
    } finally {
      _flushing = false;
    }
  }

  /// Flush and cancel timer. Call on app shutdown.
  static Future<void> dispose() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await flush();
  }

  static void _startTimer() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => flush());
  }
}
